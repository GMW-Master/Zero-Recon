#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

trap 'echo "[ERROR] Error on line $LINENO"; exit 1' ERR

bold="$(tput bold 2>/dev/null || true)"
normal="$(tput sgr0 2>/dev/null || true)"
red="$(tput setaf 1 2>/dev/null || true)"
green="$(tput setaf 2 2>/dev/null || true)"
yellow="$(tput setaf 3 2>/dev/null || true)"
cyan="$(tput setaf 6 2>/dev/null || true)"

log_info() {
    echo "${green}${bold}[INFO]${normal} $*"
}

log_warn() {
    echo "${yellow}${bold}[WARN]${normal} $*"
}

log_error() {
    echo "${red}${bold}[ERROR]${normal} $*" >&2
}

banner() {
    echo "${cyan}${bold}"
    echo "=============================="
    echo "          ZERO RECON"
    echo "=============================="
    echo "${normal}"
}

usage() {
    echo "Usage: $0 domain.com"
}

check_dependencies() {
    local tools=(
        curl jq sort sed awk
        subfinder shuffledns haktrails alterx dnsx puredns
        naabu httpx anew dirsearch gau gospider trufflehog
        nuclei gf bhedak dalfox
    )
    local missing=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done

    if ((${#missing[@]} > 0)); then
        log_error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

validate_input() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 1
    fi

    if [[ "$1" == -* || "$1" != *.* ]]; then
        log_error "Invalid domain: $1"
        usage
        exit 1
    fi
}

set_output_paths() {
    subs_raw="$scan_path/passive/subs_raw.txt"
    subs_unique="$scan_path/passive/subs_unique.txt"
    resolved_hosts="$scan_path/resolved/resolved.txt"
    alive_hosts="$scan_path/http/alive.txt"
    ports_file="$scan_path/ports/ports.txt"
    tech_file="$scan_path/http/tech.txt"
    crawl_file="$scan_path/crawl/crawl.txt"
    gau_file="$scan_path/crawl/gau.txt"
    js_urls="$scan_path/js/jsurls.txt"
    params_file="$scan_path/params/params.txt"
    api_urls="$scan_path/http/api_urls.txt"
    nuclei_output="$scan_path/nuclei/nuclei.txt"
    secret_output="$scan_path/secrets/secretfound.txt"
}

create_output_architecture() {
    set_output_paths

    mkdir -p \
        "$scan_path/passive" \
        "$scan_path/active" \
        "$scan_path/resolved" \
        "$scan_path/http" \
        "$scan_path/ports" \
        "$scan_path/crawl" \
        "$scan_path/js" \
        "$scan_path/params" \
        "$scan_path/nuclei" \
        "$scan_path/screenshots" \
        "$scan_path/secrets" \
        "$scan_path/logs" \
        "$scan_path/dirsearch" \
        "$scan_path/possible_Vul_URLs" \
        "$checkpoint_dir"

    touch "$subs_raw" "$subs_unique" "$resolved_hosts" "$alive_hosts" "$ports_file" \
        "$tech_file" "$crawl_file" "$gau_file" "$js_urls" "$params_file" "$api_urls"

    # Backward-compatible paths for users who already consume the old filenames.
    ln -sfn "passive/subs_unique.txt" "$scan_path/subs.txt"
    ln -sfn "resolved/resolved.txt" "$scan_path/resolved_uniq.txt"
    ln -sfn "http/alive.txt" "$scan_path/http.txt"
}

run_stage() {
    local checkpoint="$1"
    local fn="$2"
    local checkpoint_file="$checkpoint_dir/$checkpoint.done"

    if [[ -f "$checkpoint_file" ]]; then
        log_info "Skipping $checkpoint; checkpoint exists."
        return 0
    fi

    "$fn"
    touch "$checkpoint_file"
}

create_scope_directory() {
    log_info "Creating scope directory..."
    mkdir -p "$scope_path"

    if [[ ! -f "$scope_path/roots.txt" ]]; then
        printf '%s\n' "$id" > "$scope_path/roots.txt"
        log_info "Scope directory created for $id"
    fi

    log_info "Scope directory creation done."
}

perform_initial_setup() {
    log_info "Performing initial setup..."
    create_output_architecture
    cp "$scope_path/roots.txt" "$scan_path/roots.txt"
    log_info "Initial setup done."
}

perform_first_scan() {
    log_info "Preparing the environment..."
    cp "$scope_path/roots.txt" "$scan_path/roots.txt"
    log_info "First scan setup done."
}

perform_crtsh_scan() {
    log_info "Scanning crt.sh..."

    if ! curl -fsS "https://crt.sh/?q=%25.$id&output=json" \
        | jq -r '.[].name_value? // empty' \
        | sed 's/\*\.//g; s/\\n/\n/g' \
        | sort -u > "$scan_path/passive/crtsh.txt"; then
        log_warn "crt.sh request or parsing failed; continuing with an empty crt.sh result."
        : > "$scan_path/passive/crtsh.txt"
    fi

    cat "$scan_path/passive/crtsh.txt" >> "$subs_raw"
    sort -u "$subs_raw" > "$subs_unique"
    log_info "crt.sh data stored in $scan_path/passive/crtsh.txt"
}

perform_dns_enumeration() {
    log_info "Performing DNS enumeration..."
    log_info "This can take a while for large scopes."

    subfinder -silent -dL "$scan_path/roots.txt" >> "$subs_raw" || true
    shuffledns -silent -w "$ppath/lists/pry-dns.txt" -r "$ppath/lists/resolvers.txt" < "$scan_path/roots.txt" >> "$subs_raw" || true
    haktrails subdomains < "$scan_path/roots.txt" >> "$subs_raw" || true

    sort -u "$subs_raw" > "$subs_unique"

    if [[ -s "$subs_unique" ]]; then
        alterx -silent < "$subs_unique" | dnsx -silent >> "$subs_raw" || true
        sort -u "$subs_raw" > "$subs_unique"
    fi

    log_info "DNS enumeration done. Unique subdomains: $(wc -l < "$subs_unique")"
}

perform_dns_resolution() {
    log_info "Performing DNS resolution..."
    log_info "This can take a while for large scopes."

    if [[ ! -s "$subs_unique" ]]; then
        log_warn "No subdomains found to resolve."
        : > "$resolved_hosts"
        return 0
    fi

    puredns -q resolve "$subs_unique" -r "$ppath/lists/resolvers.txt" -w "$resolved_hosts" >/dev/null || true
    sort -u "$resolved_hosts" -o "$resolved_hosts"

    log_info "DNS resolution done. Resolved hosts: $(wc -l < "$resolved_hosts")"
    log_info "Resolved hosts stored at $resolved_hosts"
    cat "$resolved_hosts"
}

extract_ips() {
    log_info "Extracting IP addresses..."

    touch "$scan_path/resolved/ipswithCDN.txt" "$scan_path/resolved/ip_list.txt"

    if [[ -s "$subs_unique" ]]; then
        dnsx -silent -recon < "$subs_unique" | anew "$scan_path/resolved/ipswithCDN.txt" >/dev/null || true
        dnsx -silent -ro -cdn < "$subs_unique" | sort -u | sed '/\[/d' > "$scan_path/resolved/ip_list.txt" || true
    fi

    ln -sfn "resolved/ip_list.txt" "$scan_path/ip_list.txt"
    ln -sfn "resolved/ipswithCDN.txt" "$scan_path/ipswithCDN.txt"

    log_info "IP extraction done."
    cat "$scan_path/resolved/ip_list.txt"
    cat "$scan_path/resolved/ipswithCDN.txt"
}

perform_port_scanning() {
    log_info "Performing port scanning and HTTP discovery..."

    if [[ -s "$resolved_hosts" ]]; then
        naabu -l "$resolved_hosts" -o "$ports_file" >/dev/null || true
        httpx -l "$ports_file" -o "$alive_hosts" >/dev/null || true
        httpx -l "$alive_hosts" -td -title -server -ip -o "$tech_file" >/dev/null || true
    else
        log_warn "No resolved hosts available for port scanning."
    fi

    grep -Ei 'api|endpoint|gateway|interface|webservice|auth|token' "$alive_hosts" | anew "$api_urls" >/dev/null || true

    log_info "Alive web servers: $(wc -l < "$alive_hosts")"
    cat "$alive_hosts"
    log_info "Possible API URLs:"
    cat "$api_urls"
}

perform_dirSearch() {
    log_info "Performing directory scanning..."

    if [[ ! -s "$alive_hosts" ]]; then
        log_warn "No alive hosts available for directory scanning."
        return 0
    fi

    dirsearch -l "$alive_hosts" -i 200,500,405 -o "$scan_path/dirsearch/dirsearch.txt" || true
    awk '$0 ~ / 200 / {print $3}' "$scan_path/dirsearch/dirsearch.txt" > "$scan_path/dirsearch/200response.txt" || true
    awk '$0 ~ / 500 / {print $3}' "$scan_path/dirsearch/dirsearch.txt" > "$scan_path/dirsearch/500response.txt" || true
    awk '$0 ~ / 405 / {print $3}' "$scan_path/dirsearch/dirsearch.txt" > "$scan_path/dirsearch/405response.txt" || true

    if [[ -s "$scan_path/dirsearch/200response.txt" ]]; then
        dirsearch -l "$scan_path/dirsearch/200response.txt" -i 200,500 | awk '$0 ~ / 200 / {print $3}' > "$scan_path/dirsearch/200response.next.txt" || true
        mv "$scan_path/dirsearch/200response.next.txt" "$scan_path/dirsearch/200response.txt"
    fi

    if [[ -s "$scan_path/dirsearch/500response.txt" ]]; then
        dirsearch -l "$scan_path/dirsearch/500response.txt" -i 200,500 | awk '{print $3}' > "$scan_path/dirsearch/500response.next.txt" || true
        mv "$scan_path/dirsearch/500response.next.txt" "$scan_path/dirsearch/500response.txt"
    fi

    if [[ -s "$scan_path/dirsearch/405response.txt" ]]; then
        dirsearch -l "$scan_path/dirsearch/405response.txt" -i 200,500 | awk '{print $3}' > "$scan_path/dirsearch/200_post_response.txt" || true
    fi
}

perform_crawling() {
    log_info "Performing crawling..."

    gau --mc 200 "$id" > "$gau_file" || true

    if [[ -s "$alive_hosts" ]]; then
        gospider -S "$alive_hosts" --json | jq -r '.output? // empty' > "$scan_path/crawl/gospider_http.txt" || true
        cat "$scan_path/crawl/gospider_http.txt" >> "$crawl_file"
    fi

    if [[ -s "$scan_path/dirsearch/200response.txt" ]]; then
        gospider -S "$scan_path/dirsearch/200response.txt" --json | jq -r '.output? // empty' >> "$crawl_file" || true
    fi

    if [[ -s "$gau_file" ]]; then
        gospider -S "$gau_file" --json | jq -r '.output? // empty' >> "$crawl_file" || true
        cat "$gau_file" >> "$crawl_file"
    fi

    sort -u "$crawl_file" > "$scan_path/crawl/crawl.unique.txt"
    grep -F "$id" "$scan_path/crawl/crawl.unique.txt" > "$scan_path/crawl/crawl.filtered.txt" || true
    mv "$scan_path/crawl/crawl.filtered.txt" "$crawl_file"

    grep -E '\.js($|\?)' "$crawl_file" | httpx -sr -srd js -o "$js_urls" || true
    grep -E '\?.+=' "$crawl_file" | sort -u > "$params_file" || true

    log_info "Crawling done. URLs: $(wc -l < "$crawl_file")"
}

perform_secret_search() {
    log_info "Performing secret scanning..."

    if [[ -d "$scan_path/js/response" ]]; then
        trufflehog filesystem "$scan_path/js/response" > "$secret_output" || true
    else
        log_warn "No JS response directory found for secret scanning."
        : > "$secret_output"
    fi
}

perform_nuclei() {
    log_info "Performing Nuclei scan..."

    if [[ -s "$alive_hosts" ]]; then
        nuclei -l "$alive_hosts" -s low,medium,high,critical,unknown -t "$ppath/lists/nuclei-templates" -o "$nuclei_output" || true
    else
        log_warn "No alive hosts available for Nuclei."
        : > "$nuclei_output"
    fi
}

perform_Vul() {
    log_info "Performing vulnerability URL preparation and XSS scan..."

    if [[ ! -s "$crawl_file" ]]; then
        log_warn "No crawl URLs available for vulnerability routing."
        return 0
    fi

    gf xss "$crawl_file" | sed "s/'\|(\|)//g" | bhedak "FUZZ" 2>/dev/null | anew -q "$scan_path/possible_Vul_URLs/xss.txt" || true

    if [[ -s "$scan_path/possible_Vul_URLs/xss.txt" ]]; then
        dalfox file "$scan_path/possible_Vul_URLs/xss.txt" -o "$scan_path/dalfox.txt" || true
    else
        log_warn "No XSS candidate URLs found."
    fi
}

generate_report() {
    local report="$scan_path/report.md"

    {
        echo "# Zero Recon Report"
        echo
        echo "- Domain: $id"
        echo "- Scan path: $scan_path"
        echo "- Unique subdomains: $(wc -l < "$subs_unique")"
        echo "- Resolved hosts: $(wc -l < "$resolved_hosts")"
        echo "- Alive web assets: $(wc -l < "$alive_hosts")"
        echo "- Crawled URLs: $(wc -l < "$crawl_file")"
        echo "- Parameterized URLs: $(wc -l < "$params_file")"
        echo "- JS URLs: $(wc -l < "$js_urls")"
        echo "- Nuclei findings: $(wc -l < "$nuclei_output" 2>/dev/null || echo 0)"
        echo "- Secret findings: $(wc -l < "$secret_output" 2>/dev/null || echo 0)"
    } > "$report"

    log_info "Report generated at $report"
}

validate_input "$@"

id="$1"
ppath="$(pwd)"
scope_path="$ppath/scope/$id"
timestamp="$(date +%d%m%y-%H%M)"
start_epoch="$(date +%s)"
scan_path="${RESUME_SCAN_DIR:-$ppath/scans/$id-$timestamp}"
checkpoint_dir="$scan_path/.checkpoints"
set_output_paths

banner
check_dependencies
create_scope_directory
run_stage "initial_setup" perform_initial_setup
run_stage "first_scan" perform_first_scan
run_stage "crtsh_scan" perform_crtsh_scan
run_stage "dns_enumeration" perform_dns_enumeration
run_stage "dns_resolution" perform_dns_resolution
run_stage "ip_extraction" extract_ips
run_stage "port_scanning" perform_port_scanning
run_stage "dirsearch" perform_dirSearch
run_stage "crawling" perform_crawling
run_stage "secret_search" perform_secret_search
run_stage "nuclei" perform_nuclei
run_stage "vulnerability_routing" perform_Vul
generate_report

end_epoch="$(date +%s)"
seconds=$((end_epoch - start_epoch))
log_info "All stages completed in ${seconds}s."

#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

trap 'echo "[ERROR] Installer failed on line $LINENO"; exit 1' ERR

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${TOOLS_DIR:-$HOME/tools}"
GO_BIN="$(go env GOPATH 2>/dev/null || echo "$HOME/go")/bin"

log() {
    echo "[INFO] $*"
}

warn() {
    echo "[WARN] $*" >&2
}

need_sudo() {
    if [[ "$(id -u)" -eq 0 ]]; then
        echo ""
    elif command -v sudo >/dev/null 2>&1; then
        echo "sudo"
    else
        warn "sudo is not installed. Run this installer as root or install sudo."
        exit 1
    fi
}

install_system_packages() {
    local sudo_cmd
    sudo_cmd="$(need_sudo)"

    log "Installing system packages..."

    if command -v apt-get >/dev/null 2>&1; then
        $sudo_cmd apt-get update
        $sudo_cmd apt-get install -y \
            bash ca-certificates curl wget git unzip make gcc build-essential \
            jq sed gawk coreutils python3 python3-pip python3-venv golang-go
        $sudo_cmd apt-get install -y pipx || true
    elif command -v dnf >/dev/null 2>&1; then
        $sudo_cmd dnf install -y \
            bash ca-certificates curl wget git unzip make gcc gcc-c++ \
            jq sed gawk coreutils python3 python3-pip pipx golang
    elif command -v pacman >/dev/null 2>&1; then
        $sudo_cmd pacman -Sy --needed --noconfirm \
            bash ca-certificates curl wget git unzip make gcc \
            jq sed gawk coreutils python python-pip python-pipx go
    elif command -v brew >/dev/null 2>&1; then
        brew install bash ca-certificates curl wget git unzip make jq gawk python pipx go
    else
        warn "Unsupported package manager. See manual_install_and_accounts.md."
        exit 1
    fi
}

ensure_path() {
    export PATH="$GO_BIN:$HOME/.local/bin:$PATH"

    if [[ ":$PATH:" != *":$GO_BIN:"* ]]; then
        export PATH="$GO_BIN:$PATH"
    fi

    if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'go/bin' "$HOME/.bashrc"; then
        {
            echo ""
            echo "# Zero-Recon tool paths"
            echo 'export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"'
        } >> "$HOME/.bashrc"
    fi
}

go_install() {
    local module="$1"
    log "go install $module"
    GO111MODULE=on go install -v "$module"
}

install_go_tools() {
    if ! command -v go >/dev/null 2>&1; then
        warn "Go is still not available after system package install."
        exit 1
    fi

    ensure_path

    go_install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go_install github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
    go_install github.com/hakluke/haktrails@latest
    go_install github.com/projectdiscovery/alterx/cmd/alterx@latest
    go_install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
    go_install github.com/d3mondev/puredns/v2@latest
    go_install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
    go_install github.com/projectdiscovery/httpx/cmd/httpx@latest
    go_install github.com/tomnomnom/anew@latest
    go_install github.com/lc/gau/v2/cmd/gau@latest
    go_install github.com/jaeles-project/gospider@latest
    go_install github.com/trufflesecurity/trufflehog/v3@latest
    go_install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
    go_install github.com/tomnomnom/gf@latest
    go_install github.com/hahwul/dalfox/v2@latest
}

install_python_tools() {
    ensure_path

    log "Installing Python CLI tools with pipx..."
    if ! command -v pipx >/dev/null 2>&1; then
        python3 -m pip install --user --upgrade pipx --break-system-packages || \
            python3 -m pip install --user --upgrade pipx
        export PATH="$HOME/.local/bin:$PATH"
    fi

    python3 -m pipx ensurepath || true

    pipx install dirsearch || pipx upgrade dirsearch || true
    pipx install bhedak || pipx upgrade bhedak || true
}

install_massdns() {
    local sudo_cmd
    sudo_cmd="$(need_sudo)"

    if command -v massdns >/dev/null 2>&1; then
        log "massdns already installed."
        return 0
    fi

    log "Installing massdns, required by puredns..."
    mkdir -p "$TOOLS_DIR"

    if [[ ! -d "$TOOLS_DIR/massdns/.git" ]]; then
        git clone https://github.com/blechschmidt/massdns.git "$TOOLS_DIR/massdns"
    else
        git -C "$TOOLS_DIR/massdns" pull --ff-only || true
    fi

    make -C "$TOOLS_DIR/massdns"
    $sudo_cmd make -C "$TOOLS_DIR/massdns" install
}

install_gf_patterns() {
    log "Installing gf example patterns..."
    mkdir -p "$HOME/.gf" "$TOOLS_DIR"

    if [[ ! -d "$TOOLS_DIR/gf/.git" ]]; then
        git clone https://github.com/tomnomnom/gf.git "$TOOLS_DIR/gf"
    else
        git -C "$TOOLS_DIR/gf" pull --ff-only || true
    fi

    cp "$TOOLS_DIR/gf/examples/"*.json "$HOME/.gf/" || true
}

install_zero_recon_lists() {
    log "Preparing Zero-Recon lists directory..."
    mkdir -p "$ROOT_DIR/lists"

    if [[ ! -s "$ROOT_DIR/lists/resolvers.txt" ]]; then
        curl -fsSL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
            -o "$ROOT_DIR/lists/resolvers.txt"
    fi

    if [[ ! -s "$ROOT_DIR/lists/pry-dns.txt" ]]; then
        curl -fsSL https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt \
            -o "$ROOT_DIR/lists/pry-dns.txt"
    fi

    if [[ ! -d "$ROOT_DIR/lists/nuclei-templates/.git" ]]; then
        git clone https://github.com/projectdiscovery/nuclei-templates.git "$ROOT_DIR/lists/nuclei-templates"
    else
        git -C "$ROOT_DIR/lists/nuclei-templates" pull --ff-only || true
    fi
}

verify_install() {
    local required=(
        curl jq sort sed awk
        subfinder shuffledns haktrails alterx dnsx puredns
        naabu httpx anew dirsearch gau gospider trufflehog
        nuclei gf bhedak dalfox massdns
    )
    local missing=()

    ensure_path

    for tool in "${required[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done

    if ((${#missing[@]} > 0)); then
        warn "Some tools are still missing: ${missing[*]}"
        warn "Open manual_install_and_accounts.md for direct install commands and account setup."
        return 1
    fi

    log "All required commands are available."
}

main() {
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        echo "Usage: bash install_dependencies.sh"
        echo "Installs Zero-Recon dependencies on Debian/Kali/Ubuntu, Fedora, Arch, or macOS Homebrew."
        exit 0
    fi

    install_system_packages
    ensure_path
    install_go_tools
    install_python_tools
    install_massdns
    install_gf_patterns
    install_zero_recon_lists
    verify_install || true

    log "Installer finished."
    log "Restart your shell or run: export PATH=\"\$HOME/go/bin:\$HOME/.local/bin:\$PATH\""
    log "Next: read manual_install_and_accounts.md for SecurityTrails/haktrails API setup."
}

main "$@"

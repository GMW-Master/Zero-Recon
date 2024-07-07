#!/bin/bash

# Color and formatting variables
bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)

banner()
{
  echo " ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄       ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄ 
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░▌      ▐░▌
 ▀▀▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌     ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░▌░▌     ▐░▌
          ▐░▌▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌       ▐░▌▐░▌          ▐░▌          ▐░▌       ▐░▌▐░▌▐░▌    ▐░▌
 ▄▄▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░▌          ▐░▌       ▐░▌▐░▌ ▐░▌   ▐░▌
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌          ▐░▌       ▐░▌▐░▌  ▐░▌  ▐░▌
▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀█░█▀▀ ▐░▌       ▐░▌     ▐░█▀▀▀▀█░█▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌          ▐░▌       ▐░▌▐░▌   ▐░▌ ▐░▌
▐░▌          ▐░▌          ▐░▌     ▐░▌  ▐░▌       ▐░▌     ▐░▌     ▐░▌  ▐░▌          ▐░▌          ▐░▌       ▐░▌▐░▌    ▐░▌▐░▌
▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌      ▐░▌ ▐░█▄▄▄▄▄▄▄█░▌     ▐░▌      ▐░▌ ▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▐░▌     ▐░▐░▌
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌     ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌      ▐░░▌
 ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀ 
                                                                                                                          "
}

# Function to create scope directory if not exists
create_scope_directory() {
    echo "${green}${bold}Creating scope directory...${normal}"
    if [ ! -d "$scope_path" ]; then
        mkdir "$ppath/scope/$id" > /dev/null 2>&1
        echo "$id" >> roots.txt
        mv roots.txt "$scope_path/"
        echo "${green}${bold} Scope directory created for $id${normal}"
    fi
    echo "S${green}${bold}cope directory creation done.${normal}"
}

# Function to perform initial setup for scan
perform_initial_setup() {
    echo "${green}${bold}Performing initial setup...${normal}"
    mkdir -p "$scan_path" > /dev/null 2>&1
    cd "$scan_path" > /dev/null 2>&1
    echo "${green}${bold}Initial setup done.${normal}"
}

# Function to perform first scan
perform_first_scan() {
    echo "${green}${bold}Preparing the environment ${normal}"
    
    
    cp -v "$scope_path/roots.txt" "$scan_path/roots.txt" > /dev/null 2>&1
    sleep 3

    end_time=$(date +%s)
    seconds=$((end_time - timestamp))
    time=""

    

    echo "${green}${bold}Scan $id took $seconds ${normal}"
    echo "${green}${bold}First scan done.${normal}"
}

# Function to perform second scan
perform_second_scan() {
    echo " ${green}${bold}Scaning crt.sh ${normal}"
    
    cat "$scope_path/roots.txt" > /dev/null 2>&1
    cp -v "$scope_path/roots.txt" "$scan_path/roots.txt" > /dev/null 2>&1
    curl -s https://crt.sh/?q=.$1\&output\=json | jq . | grep 'name_value' | awk '{print $2}' | sed -e 's/"//g'| sed -e 's/,//g' |  awk '{gsub(/\\n/,"\n")}1' | sort -u > "$scan_path/subs.txt"
    echo "${green}${bold}data downloaded and stored from crt.sh ${normal}"
}

# Function to perform DNS enumeration
perform_dns_enumeration() {
    echo "${green}${bold}Performing DNS enumeration...${normal}"
    echo "${bold}have coffe and come back , I will take more time , if the scope is big ${normal}"
    cat "$scan_path/roots.txt" | subfinder -s | anew subs.txt > /dev/null 2>&1
    cat "$scan_path/roots.txt" | shuffledns -silent -w "$ppath/lists/pry-dns.txt" -r "$ppath/lists/resolvers.txt" | anew subs.txt > /dev/null 2>&1
    cat "$scan_path/roots.txt" | haktrails subdomains | anew subs.txt | wc -l > /dev/null 2>&1
    cat "$scan_path/roots.txt" | subfinder -s | anew subs.txt | wc -l > /dev/null 2>&1
    cat "$scan_path/roots.txt" | shuffledns -silent -w "$ppath/lists/pry-dns.txt" -r "$ppath/lists/resolvers.txt" | anew subs.txt | wc -l > /dev/null 2>&1
    cat "$scan_path/subs.txt" | alterx -silent | dnsx -silent | anew subs.txt > /dev/null 2>&1
    echo "${green}${bold}DNS enumeration done.${normal}"
}

# Function to perform DNS resolution
perform_dns_resolution() {
    echo "${green}${bold}Performing DNS resolution...${normal}"
    echo "${bold}have coffe and come back , I will take more time , if the scope is big ${normal}"
    puredns -q resolve "$scan_path/subs.txt" -r "$ppath/lists/resolvers.txt" -w "$scan_path/resolved.txt" | wc -l > /dev/null
    cat "$scan_path/subs.txt" | anew resolved.txt > /dev/null 2>&1
    touch "$scan_path/resolved_uniq.txt"
    sort "$scan_path/resolved.txt" | uniq | anew "$scan_path/resolved_uniq.txt" > /dev/null 2>&1
    echo "${green}${bold}DNS resolution done.${normal}"
    echo "${green}${bold} LIST OF ACTIVE SUBDOMAINS stored at $scan_path/resolved_uniq.txt  ${normal}"
    cat "$scan_path/resolved_uniq.txt" 
}

# Function to extract IP addresses and remove the CDN IPs
extract_ips() {
    echo "${green}${bold}Extracting IP addresses...${normal}"
    touch "$scan_path/ipswithCDN.txt"
    cat "$scan_path/subs.txt" | dnsx -silent -recon | anew "$scan_path/ipswithCDN.txt" > /dev/null 2>&1
    echo "${green}${bold}Removing CDN and Dublicate IP addresses${normal}"
    cat "$scan_path/subs.txt" | dnsx -silent -ro -cdn | anew "$scan_path/ips.txt" > /dev/null 2>&1
    touch "$scan_path/ip_list.txt"
    cat "$scan_path/ips.txt" | sort | uniq | anew "$scan_path/ip_list.txt" > /dev/null 2>&1
    sed -i '/\[/d' "$scan_path/ip_list.txt" > /dev/null 2>&1
    echo "${green}${bold}IP extraction done.${normal}"
    echo "${green}${bold} LIST OF IP ADDRESS - EXCLUDED CDN WAF IPs ipWithUrl.txt  ip_list.txt ${normal}"
    rm "$scan_path/ips.txt"
    cat "$scan_path/ip_list.txt"
    cat "$scan_path/ipswithCDN.txt"
}

# Function to perform port scanning and HTTP server discovery
perform_port_scanning() {
    echo "${green}${bold}Performing port scanning...${normal}"
    naabu -l "$scan_path/resolved_uniq.txt" -o "$scan_path/httpx.txt" > /dev/null 2>&1
    httpx -l "$scan_path/httpx.txt" -o "$scan_path/http.txt" > /dev/null 2>&1
    echo "${green}${bold} LIST OF WEB-SERVERS WITH PORT NUMBERS  ${normal}"
    cat "$scan_path/http.txt"
    echo "${green}${bold}Finding Possible API urls${normal}"
    touch "$scan_path/api_urls.txt"
    cat "$scan_path/http.txt" | grep -e Api -e endpoint -e gateway -e interface -e webservice -e auth -e token | anew "$scan_path/api_urls.txt" > /dev/null 2>&1
    echo "${green}${bold}Port scanning done.${normal}"
    cat "$scan_path/api_urls.txt"
}

perform_dirSearch() {
    echo "${green}${bold}Performing directory scanning...${normal}"
    mkdir dirsearch
    dirsearch -l $scan_path/http.txt -i 200,500,405 -o $scan_path/dirsearch/dirsearch.txt
    cat $scan_path/dirsearch/dirsearch.txt | grep 200 | awk '{print $3}' > $scan_path/dirsearch/200response.txt
    cat $scan_path/dirsearch/dirsearch.txt | grep 500 | awk '{print $3}' > $scan_path/dirsearch/500response.txt
    cat $scan_path/dirsearch/dirsearch.txt | grep 405 | awk '{print $3}' > $scan_path/dirsearch/405response.txt
    dirsearch -l $scan_path/dirsearch/200response.txt -i 200,500 | grep 200 | awk '{print $3}' | tee $scan_path/dirsearch/200response.txt
    dirsearch -l $scan_path/dirsearch/500response.txt -i 200,500   | awk '{print $3}' | tee $scan_path/dirsearch/200response.txt
    dirsearch -l $scan_path/dirsearch/405response.txt -i 200,500   | awk '{print $3}' | tee $scan_path/dirsearch/200_post_response.txt
    
}

perform_crawling() {
        echo "${green}${bold}Performing crawling...${normal}"
        gau --mc 200 $id | tee $scan_path/gau.txt > /dev/null 2>&1
        gospider -S $scan_path/http.txt --json | jq -r '.output' | tee $scan_path/crawl.txt > /dev/null 2>&1
        gospider -S $scan_path/dirsearch/200response.txt --json | jq -r '.output' | anew $scan_path/crawl.txt > /dev/null 2>&1
        gospider -S $scan_path/gau.txt --json | jq -r '.output' | anew $scan_path/crawl.txt > /dev/null 2>&1
        cat $scan_path/crawl.txt | grep "$id" > $scan_path/crawl.txt
        cat "$scan_path/crawl.txt" | grep "\.js" | httpx -sr -srd js -o "$scan_path/jsurls.txt"
}

perform_secret_search() {
        echo "${green}${bold}Performing Secret scanning...${normal}"

        trufflehog filesystem "$scan_path/js/response/*" > "$scan_path/secrectfound.txt"
        
}

perform_nuclei() {

        echo "${green}${bold}Performing Nuclei Scan...${normal}"
        
        nuclei -l "$scan_path/http.txt" -s low, medium, high, critical, unknown -t "$ppath/lists/nuclei-templates" -o "$scan_path/nucle.txt"
     
}

perform_Vul() {

        echo "${green}${bold}Performing vulnerability scan...${normal}"
        mkdir $scan_path/possible_Vul_URLs
        
         gf xss $scan_path/crawl.txt | sed "s/'\|(\|)//g" | bhedak "FUZZ" 2> /dev/null | anew -q $scan_path/possible_Vul_URLs/xss.txt
         dalfox file $scan_path/possible_Vul_URLs/xss.txt -o $scan_path/dalfox.txt
}


id="$1"
ppath="$(pwd)"
scope_path="$ppath/scope/$id"
timestamp="$(date +%d%m%y-%H%M)"
scan_path="$ppath/scans/$id-$timestamp"

banner
create_scope_directory
perform_initial_setup
perform_first_scan
perform_second_scan
perform_dns_enumeration
perform_dns_resolution
extract_ips
perform_port_scanning
perform_dirSearch
perform_crawling
perform_secret_search
perform_nuclei
perform_Vul

echo "${bold}${green}All stages completed.${normal}"

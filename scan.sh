#!/bin/bash 
id="$1"
ppath="$(pwd)"
scope_path="$ppath/scope/$id"

timestamp="$(date +%d%m%y-%H%M)"
scan_path="$ppath/scans/$id-$timestamp"

if [ ! -d "$scope_path" ]; then
	mkdir "$ppath/scope/$id" | echo "$id" >> roots.txt | mv roots.txt "$scope_path/"
fi

mkdir -p "$scan_path"
cd "$scan_path"

### Perform scan ### 
echo "Starting scan against roots:"
cat "$scope_path/roots.txt"
cp -v "$scope_path/roots.txt" "$scan_path/roots.txt"
sleep 3

end_time=$(date +%s)
seconds="$(expr $end_time - $timestamp)"
time=""

if [[ "$seconds" -gt 59 ]]
then
	minutes=$(expr $seconds / 60)
	time="$minutes minutes"
else
	time="$seconds seconds"
fi

echo "Scan $id took $time"

## Perform Scan ##
$2=".$1"
echo "$2"
echo "Starting Full Recon Scan Against : "
cat "$scope_path/roots.txt"
cp -v "$scope_path/roots.txt" "$scan_path/roots.txt"
curl https://crt.sh/?q=.$1\&output\=json | jq . | grep 'name_value' | awk '{print $2}' | sed -e 's/"//g'| sed -e 's/,//g' |  awk '{gsub(/\\n/,"\n")}1' | sort -u > "$scan_path/subs.txt" 
#DNS Bruteforcing 
cat "$scan_path/roots.txt" | subfinder | anew subs.txt
cat "$scan_path/roots.txt" | shuffledns -w "$ppath/lists/pry-dns.txt" -r "$ppath/lists/resolvers.txt" | anew subs.txt

# DNS Enumeration - Find Subdomains 
cat "$scan_path/roots.txt" | haktrails subdomains | anew subs.txt | wc -l
cat "$scan_path/roots.txt" | subfinder | anew subs.txt | wc -l 
cat "$scan_path/roots.txt" | shuffledns -w "$ppath/lists/pry-dns.txt" -r "$ppath/lists/resolvers.txt" | anew subs.txt | wc -l
cat "$scan_path/subs.txt" | alterx | dnsx | anew subs.txt
#cp "$scan_path/subs.txt" "$scan_path/resolved.txt"
# DNS Resolution - Find Subdomains 
puredns resolve "$scan_path/subs.txt" -r "$ppath/lists/resolvers.txt" -w "$scan_path/resolved.txt" | wc -l 
dnsx -l "$scan_path/resolved.txt" -json -o "$scan_path/dns.json" | jq -r '.a?[]?' | anew "$scan_path/ips.txt" | wc -l
cat "$scan_path/subs.txt" | anew resolved.txt
sort "$scan_path/resolved.txt" | uniq > "$scan_path/resolved_uniq.txt"
#Port Scanning & HTTP Server Discovery 

#nmap -T4 -vv -iL "$scan_path/ips.txt" --top-ports 3000 -n --open -oX "$scan_path/nmap.xml"
#tew -x "$scan_path/nmap.xml" -dnsx "$scan_path/dns.json" --vhost -o "$scan_path/hostport.txt" | httpx -sr -srd "$scan_path/responses" -json -o "$scan_path/http.json"

#cat "$scan_path/http.json" | jq -r '.url' | sed -e "s/:80$//g" -e 's/:443$//g' | sort -u > "$scan_path/http.txt"
naabu -l "$scan_path/resolved_uniq.txt" -o "$scan_path/httpx.txt"
httpx -l "$scan_path/httpx.txt" -o "$scan_path/http.txt"

dirsearch -l "$scan_path/http.txt" -x 300-599 -o "$scan_path/httpdir.txt"
grep -Eo '(https?://[^ ]+|/[^\s]*)' "$scan_path/httpdir.txt" > "$scan_path/httpdir1.txt"

#Crawling

gospider -S "$scan_path/http.txt" --json | grep "{" | jq -r '.output?' | tee "$scan_path/crawl.txt" 

#Javascript Pulling
cat "$scan_path/crawl.txt" | grep "\.js" | httpx -sr -srd js -o "$scan_path/jsurls.txt"
waybackurls $1 | httpx | anew "$scan_path/httpdir1.txt"
#XSS
echo "XSS Scanning"
cat "$scan_path/httpdir1.txt" | gf xss > "$scan_path/xssurls.txt"
sort "xssurls.txt" | uniq > "$scan_path/xssurls_final.txt"
dalfox -F file "$scan_path/xssurls_final.txt" 
#nuclei
nuclei -l "$scan_path/httpdir1.txt" -t /home/kali/recon24/nuclei-templates/ -o "$scan_path/nucleicommon.txt"
nuclei -l "$scan_path/jsurls.txt" -t /home/kali/recon24/nuclei-templates/ -o "$scan_path/nucleijs.txt"
trufflehog filesystem "$scan_path/js/response/*" > "$scan_path/secrectfinds.txt"



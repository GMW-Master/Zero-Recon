# Zero-Recon Manual Install And Account Setup

Use this file when `install_dependencies.sh` cannot finish something automatically.

## Recommended Platform

Run Zero-Recon from Kali, Ubuntu, Debian, or WSL2 Ubuntu/Kali. The recon script is Bash-first and expects Linux-style tools and paths.

Before running scans, make sure you have permission for the target domain.

## Quick Installer

```bash
cd /path/to/zeroRecon
bash install_dependencies.sh
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"
```

Then verify:

```bash
bash Zero-Recon-v1.sh
```

Expected output without a domain:

```text
Usage: Zero-Recon-v1.sh domain.com
```

## Direct System Package Commands

Debian, Ubuntu, Kali:

```bash
sudo apt-get update
sudo apt-get install -y bash ca-certificates curl wget git unzip make gcc build-essential jq sed gawk coreutils python3 python3-pip python3-venv pipx golang-go
```

Fedora:

```bash
sudo dnf install -y bash ca-certificates curl wget git unzip make gcc gcc-c++ jq sed gawk coreutils python3 python3-pip pipx golang
```

Arch:

```bash
sudo pacman -Sy --needed --noconfirm bash ca-certificates curl wget git unzip make gcc jq sed gawk coreutils python python-pip python-pipx go
```

macOS with Homebrew:

```bash
brew install bash ca-certificates curl wget git unzip make jq gawk python pipx go
```

## PATH Setup

Most Go tools install into `~/go/bin`, and Python user tools often install into `~/.local/bin`.

```bash
echo 'export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

For Zsh:

```bash
echo 'export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Direct Go Tool Install Commands

```bash
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
go install -v github.com/hakluke/haktrails@latest
go install -v github.com/projectdiscovery/alterx/cmd/alterx@latest
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install -v github.com/d3mondev/puredns/v2@latest
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/tomnomnom/anew@latest
go install -v github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/jaeles-project/gospider@latest
go install -v github.com/trufflesecurity/trufflehog/v3@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/tomnomnom/gf@latest
go install -v github.com/hahwul/dalfox/v2@latest
```

## Direct Python Tool Install Commands

```bash
python3 -m pipx ensurepath
pipx install dirsearch
pipx install bhedak
```

If `pipx` is unavailable:

```bash
python3 -m pip install --user --upgrade pipx
export PATH="$HOME/.local/bin:$PATH"
pipx install dirsearch
pipx install bhedak
```

## puredns Requirement: massdns

`puredns` needs `massdns`.

```bash
mkdir -p "$HOME/tools"
git clone https://github.com/blechschmidt/massdns.git "$HOME/tools/massdns"
make -C "$HOME/tools/massdns"
sudo make -C "$HOME/tools/massdns" install
```

## Required Local Lists

The recon script expects these paths:

```text
lists/resolvers.txt
lists/pry-dns.txt
lists/nuclei-templates/
```

Create them manually:

```bash
mkdir -p lists
curl -fsSL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt -o lists/resolvers.txt
curl -fsSL https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt -o lists/pry-dns.txt
git clone https://github.com/projectdiscovery/nuclei-templates.git lists/nuclei-templates
```

Update later:

```bash
git -C lists/nuclei-templates pull --ff-only
```

## gf Pattern Setup

`gf` is only the engine. It needs JSON patterns.

```bash
mkdir -p "$HOME/.gf" "$HOME/tools"
git clone https://github.com/tomnomnom/gf.git "$HOME/tools/gf"
cp "$HOME/tools/gf/examples/"*.json "$HOME/.gf/"
```

Optional extra community patterns:

```bash
git clone https://github.com/1ndianl33t/Gf-Patterns "$HOME/tools/Gf-Patterns"
cp "$HOME/tools/Gf-Patterns/"*.json "$HOME/.gf/"
```

## Account/API Setup

### SecurityTrails For haktrails

`haktrails` requires a SecurityTrails API key.

1. Create/sign in to a SecurityTrails account.
2. Open the API credentials page.
3. Create or copy an API key.
4. Create the config file:

```bash
mkdir -p "$HOME/.config/haktools"
nano "$HOME/.config/haktools/haktrails-config.yml"
```

Put this inside:

```yaml
securitytrails:
  key: YOUR_SECURITYTRAILS_API_KEY
```

Verify:

```bash
haktrails ping
haktrails usage
```

Notes:

- SecurityTrails API usage is credit-based.
- `cat roots.txt | haktrails subdomains` can consume one API request per domain.
- Keep the key out of Git and screenshots.

### subfinder Provider Keys

`subfinder` works without API keys, but it gets better results with provider keys.

Create the config folder by running:

```bash
subfinder -h >/dev/null
```

Then edit the provider config. Common locations:

```bash
nano "$HOME/.config/subfinder/provider-config.yaml"
nano "$HOME/.config/subfinder/config.yaml"
```

Add only keys for services you own or are allowed to use. Common providers include SecurityTrails, Shodan, Censys, GitHub, VirusTotal, Chaos, and BinaryEdge.

### ProjectDiscovery Cloud

`nuclei`, `subfinder`, `httpx`, and related ProjectDiscovery tools can run locally without a ProjectDiscovery Cloud account for this script. A cloud account is optional.

## Verify Everything

```bash
for tool in curl jq sort sed awk subfinder shuffledns haktrails alterx dnsx puredns naabu httpx anew dirsearch gau gospider trufflehog nuclei gf bhedak dalfox massdns; do
  command -v "$tool" >/dev/null && echo "[OK] $tool" || echo "[MISS] $tool"
done
```

## Run Zero-Recon

```bash
bash Zero-Recon-v1.sh example.com
```

Resume a partially completed scan:

```bash
RESUME_SCAN_DIR="/absolute/path/to/scans/example.com-300526-0120" bash Zero-Recon-v1.sh example.com
```

## Sources

- haktrails installation and config: https://github.com/hakluke/haktrails
- SecurityTrails API key/authentication: https://docs.securitytrails.com/docs/authentication
- puredns and massdns requirement: https://github.com/d3mondev/puredns
- gospider install command: https://github.com/jaeles-project/gospider
- bhedak install command: https://github.com/R0X4R/bhedak

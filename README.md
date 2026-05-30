# Zero-Recon

Zero-Recon is a reconnaissance automation framework designed for Bug Bounty Hunters, Pentesters, and Red Teamers. It automates target enumeration, asset discovery, URL collection, vulnerability identification, and result organization into a streamlined workflow.

---

## Features

* Automated reconnaissance workflow
* Subdomain enumeration from multiple sources
* DNS and IP intelligence gathering
* Live host discovery
* URL and endpoint collection
* Screenshot collection
* Vulnerability scanning integration
* Organized output structure
* Parallelized execution for improved performance
* Bug bounty focused workflow

---

## Installation

Clone the repository:

```bash
git clone https://github.com/piratesshield/Zero-Recon.git
cd Zero-Recon
```

### Automatic Dependency Installation

Zero-Recon includes an automated dependency installer:

```bash
chmod +x install_dependencies.sh
./install_dependencies.sh
```

The installer will download and configure the required reconnaissance tools and dependencies used by Zero-Recon.

---

## Manual Installation

If you prefer to install tools manually or encounter issues with the automated installer, refer to:

```text
manual_install_and_accounts.md
```

This document contains:

* Manual tool installation instructions
* Required account registrations
* API key setup guidance
* Troubleshooting information

---

## Configuration

### Haktrails Configuration

Zero-Recon uses Haktrails for passive reconnaissance and intelligence gathering.

Before running the framework, edit:

```text
haktrails-config.yml
```

Replace the placeholder value with your own API key:

```yaml
api_key: YOUR_HAKTRAILS_API_KEY
```

> Important: The provided configuration file is only a template. You must add your own API key before using Haktrails-related functionality.

Never commit or publicly share your personal API keys.

---

## Usage

Basic Usage:

```bash
chmod +x Zero-Recon-v1.sh
./Zero-Recon-v1.sh target.com
```

Example:

```bash
./Zero-Recon-v1.sh example.com
```

---

## Output Structure

Reconnaissance results are automatically organized into dedicated directories such as:

* Subdomains
* DNS Information
* Live Hosts
* URLs
* Screenshots
* Vulnerability Findings
* Reports

This structure makes it easier to review findings and continue manual testing.

---

## Requirements

* Linux (Recommended: Kali Linux, Ubuntu)
* Bash
* Internet Connectivity
* Required API Keys (see `manual_install_and_accounts.md`)
* Sufficient disk space for reconnaissance results

---

## Recommended Workflow

1. Install dependencies using `install_dependencies.sh`
2. Configure required API keys
3. Update `haktrails-config.yml`
4. Review `manual_install_and_accounts.md`
5. Run Zero-Recon against an authorized target
6. Review results and perform manual validation

---

## Disclaimer

This project is intended for:

* Authorized Penetration Testing
* Bug Bounty Programs
* Security Research
* Educational Purposes

Users are responsible for ensuring they have proper authorization before testing any target. The author is not responsible for misuse or illegal activities performed using this tool.

---

## Contributing

Contributions, bug reports, feature requests, and pull requests are welcome.

If you discover a bug or have an idea for improving Zero-Recon, feel free to open an issue or submit a pull request.

---

## License

MIT License

Use responsibly.

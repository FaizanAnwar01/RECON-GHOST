#!/bin/bash
# RECON GHOST - Advanced Reconnaissance Toolkit
# Developed by FORTIS SECURITY
# Version: 1.0.0
# Description: A comprehensive reconnaissance tool for domain enumeration, port scanning, web fuzzing, and vulnerability scanning.
# Dependencies: figlet, amass, subfinder, httpx, nmap, ffuf, nuclei, aquatone
# License: MIT License
# Usage: ./reconghost.sh -d <domain> -o <output_dir> -w <wordlist>
# This script is designed to automate the reconnaissance process for security assessments.
# It performs subdomain enumeration, live host probing, port scanning, web fuzzing, and vulnerability scanning using Nuclei.
# The results are saved in a structured directory format for easy access and analysis.
# This script is intended for educational and ethical hacking purposes only. Use responsibly and with permission.
# ===== TOOL CONFIGURATION =====
# This script is designed to automate the reconnaissance process for security assessments.
# It performs subdomain enumeration, live host probing, port scanning, web fuzzing, and vulnerability scanning using Nuclei.
# The results are saved in a structured directory format for easy access and analysis.
# This script is intended for educational and ethical hacking purposes only. Use responsibly and with permission.
# ===== DEPENDENCIES =====
# Ensure the following tools are installed:
# - figlet
# - amass
# - subfinder
# - httpx
# - nmap
# - ffuf
# - nuclei
# - aquatone
# You can install them using the following commands:
# sudo apt install figlet amass
# go install -v github.com/projectdiscovery/{subfinder,httpx,nuclei}@latest
# go install github.com/ffuf/ffuf@latest
# go install github.com/michenriksen/aquatone@latest
# Make sure to add the Go bin directory to your PATH:
# export PATH=$PATH:$(go env GOPATH)/bin
# This script is designed to be run on a Linux system with the necessary tools installed.
# It is recommended to run this script with root privileges for full functionality.
# This script is intended for educational and ethical hacking purposes only. Use responsibly and with permission.
# ===== LICENSE =====
# This script is licensed under the MIT License.
 
# ===== TOOL METADATA =====
TOOL_NAME="RECON GHOST"
VERSION="1.0.0"
COMPANY="FORTIS SECURITY"

# ===== COLORS =====
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# ===== CONFIG =====
WORDLIST="/usr/share/wordlists/dirb/common.txt"  # Kali default
THREADS=20

# ===== ASCII BANNER =====
display_header() {
  echo -e "${GREEN}$(figlet -f slant "RECON GHOST")${RESET}"
  echo -e "${BLUE}          Developed by ${YELLOW}$COMPANY${RESET}"
  echo -e "${RED}         Advanced Reconnaissance Toolkit${RESET}\n"
}

# ===== HELP MENU =====
show_help() {
  display_header
  echo -e "${GREEN}Usage: $TOOL_NAME [options]${RESET}"
  echo -e "\n${YELLOW}Options:${RESET}"
  echo -e "  -h, --help        Show this help"
  echo -e "  -v, --version     Show version"
  echo -e "  -d <domain>       Target domain (required)"
  echo -e "  -o <output_dir>   Output directory (required)"
  echo -e "  -w <wordlist>     Custom wordlist (default: $WORDLIST)"
  echo -e "\n${BLUE}Example:${RESET}"
  echo -e "  ./reconghost.sh -d example.com -o ./scan_results -w ~/custom_wordlist.txt\n"
  exit 0
}

# ===== VERSION DISPLAY =====
show_version() {
  display_header
  echo -e "${GREEN}$TOOL_NAME $VERSION${RESET}"
  echo -e "Subfinder $(subfinder -version 2>&1 | grep -oP 'v\d+\.\d+\.\d+')"
  echo -e "Nuclei $(nuclei -version 2>&1 | head -n1)"
  echo -e "${BLUE}Powered by $COMPANY${RESET}\n"
  exit 0
}

# ===== DEPENDENCY CHECK =====
check_dependencies() {
  local missing=()
  for cmd in figlet amass subfinder httpx nmap ffuf nuclei; do
    if ! command -v "$cmd" &> /dev/null; then
      missing+=("$cmd")
    fi
  done
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}[!] Missing dependencies:${RESET}"
    for dep in "${missing[@]}"; do
      echo -e "  - $dep"
    done
    echo -e "\nInstall with:"
    echo -e "  sudo apt install figlet amass"
    echo -e "  go install -v github.com/projectdiscovery/{subfinder,httpx,nuclei}@latest"
    exit 1
  fi
}

# ===== MAIN RECON FUNCTION =====
run_recon() {
  local DOMAIN="$1"
  local OUTPUT_DIR="$2"
  local WORDLIST="$3"

  # Create directories
  mkdir -p "$OUTPUT_DIR"/{subdomains,ports,web,screenshots,nuclei} || {
    echo -e "${RED}[!] Failed to create output directories. Check permissions.${RESET}"
    exit 1
  }

  # ---- Phase 1: Subdomains ----
  echo -e "\n${GREEN}[+] Subdomain Enumeration${RESET}"
  amass enum -passive -d "$DOMAIN" -o "$OUTPUT_DIR/subdomains/amass.txt" || {
    echo -e "${RED}[!] Amass failed. Skipping...${RESET}"
  }
  subfinder -d "$DOMAIN" -o "$OUTPUT_DIR/subdomains/subfinder.txt" || {
    echo -e "${RED}[!] Subfinder failed. Skipping...${RESET}"
  }
  cat "$OUTPUT_DIR"/subdomains/*.txt 2>/dev/null | sort -u > "$OUTPUT_DIR/subdomains/final.txt" || {
    echo -e "${RED}[!] No subdomains found. Exiting.${RESET}"
    exit 1
  }

  # ---- Phase 2: Live Hosts ----
  echo -e "\n${GREEN}[+] Probing Live Hosts${RESET}"
  httpx -l "$OUTPUT_DIR/subdomains/final.txt" -silent -o "$OUTPUT_DIR/live_hosts.txt" || {
    echo -e "${RED}[!] httpx failed. Using manual cleanup...${RESET}"
    sed 's|https\?://||' "$OUTPUT_DIR/subdomains/final.txt" > "$OUTPUT_DIR/live_hosts.txt"
  }

  # ---- Phase 3: Port Scanning ----
  echo -e "\n${GREEN}[+] Port Scanning${RESET}"
  sed 's|https\?://||;s|/.*||' "$OUTPUT_DIR/live_hosts.txt" > "$OUTPUT_DIR/nmap_targets.txt"
  nmap -iL "$OUTPUT_DIR/nmap_targets.txt" -T4 --top-ports 100 -oN "$OUTPUT_DIR/ports/nmap.txt" || {
    echo -e "${RED}[!] Nmap failed. Skipping deep scans.${RESET}"
  }

  # ---- Phase 4: Web Fuzzing ----
  if [ -f "$WORDLIST" ]; then
    echo -e "\n${GREEN}[+] Web Fuzzing${RESET}"
    while read -r url; do
      FILENAME=$(echo "$url" | sed 's|[/:]|_|g')
      ffuf -u "$url/FUZZ" -w "$WORDLIST" -o "$OUTPUT_DIR/web/$FILENAME.json" -t "$THREADS" || {
        echo -e "${RED}[!] FFuF failed for $url. Skipping...${RESET}"
      }
    done < "$OUTPUT_DIR/live_hosts.txt"
  else
    echo -e "\n${RED}[!] Wordlist not found at $WORDLIST. Skipping FFuF.${RESET}"
  fi

  # ---- Phase 5: Screenshots ----
  echo -e "\n${GREEN}[+] Capturing Screenshots${RESET}"
  sed 's|https\?://||;s|/.*||' "$OUTPUT_DIR/live_hosts.txt" > "$OUTPUT_DIR/aquatone_targets.txt"
  if command -v aquatone &> /dev/null; then
    cat "$OUTPUT_DIR/aquatone_targets.txt" | aquatone -out "$OUTPUT_DIR/screenshots" || {
      echo -e "${RED}[!] Aquatone failed. Screenshots skipped.${RESET}"
    }
  else
    echo -e "${RED}[!] Aquatone not installed. Install with: go install github.com/michenriksen/aquatone@latest${RESET}"
  fi

  # ---- Phase 6: Nuclei Scan ----
  echo -e "\n${GREEN}[+] Running Nuclei (CVE Scan)${RESET}"
  nuclei -l "$OUTPUT_DIR/live_hosts.txt" \
    -t ~/nuclei-templates/ \
    -severity medium,high,critical \
    -o "$OUTPUT_DIR/nuclei/results.txt" \
    -silent || {
    echo -e "${RED}[!] Nuclei failed.${RESET}"
  }

  echo -e "\n${YELLOW}[✅] RECON COMPLETED! Results saved to: $OUTPUT_DIR${RESET}"
}

# ===== MAIN EXECUTION =====
check_dependencies
display_header

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help) show_help ;;
    -v|--version) show_version ;;
    -d) DOMAIN="$2"; shift ;;
    -o) OUTPUT_DIR="$2"; shift ;;
    -w) WORDLIST="$2"; shift ;;
    *) echo -e "${RED}[!] Unknown option: $1${RESET}"; show_help; exit 1 ;;
  esac
  shift
done

# Validate required arguments
if [[ -z "$DOMAIN" || -z "$OUTPUT_DIR" ]]; then
  echo -e "${RED}[!] Error: Missing -d (domain) or -o (output directory)${RESET}"
  show_help
  exit 1
fi

# Run recon
run_recon "$DOMAIN" "$OUTPUT_DIR" "$WORDLIST"
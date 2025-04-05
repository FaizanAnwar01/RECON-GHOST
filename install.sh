#!/bin/bash
# RECON GHOST - Advanced Reconnaissance Toolkit
# Developed by FORTIS SECURITY
# Version: 1.0.0
#
# This script installs the necessary dependencies for RECON GHOST.
# Licensed under the MIT License.
#
# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[1;31mPlease run as root or use sudo.\033[0m"
    exit 1
fi
# Check if the script is run on a supported OS
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "\033[1;31mThis script is only supported on Linux.\033[0m"
    exit 1
fi
# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo -e "\033[1;31mGo is not installed. Please install Go first.\033[0m"
    exit 1
fi
# Check if Go is in the PATH
if ! echo "$PATH" | grep -q "$(go env GOPATH)/bin"; then
    echo -e "\033[1;31mGo bin directory is not in PATH. Adding it now...\033[0m"
    echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
    source ~/.bashrc
fi
# Check if the necessary tools are installed
if ! command -v figlet &> /dev/null || ! command -v amass &> /dev/null || ! command -v subfinder &> /dev/null || ! command -v httpx &> /dev/null || ! command -v nmap &> /dev/null || ! command -v ffuf &> /dev/null || ! command -v nuclei &> /dev/null; then
    echo -e "\033[1;31mSome dependencies are missing. Installing them now...\033[0m"
else
    echo -e "\033[1;32mAll dependencies are already installed.\033[0m"
    exit 0
fi
fi

echo -e "\033[1;34mInstalling RECON GHOST dependencies...\033[0m"

# Install system packages
sudo apt update && sudo apt install -y \
    figlet \
    nmap \
    golang

# Install Go tools
go install -v github.com/ffuf/ffuf@latest
go install -v github.com/OWASP/Amass/v3/...@latest
go install -v github.com/projectdiscovery/nmap-parser/cmd/nmap-parser@latest
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install -v github.com/projectdiscovery/katana/cmd/katana@latest
go install -v github.com/projectdiscovery/waybackurls@latest
go install -v github.com/tomnomnom/assetfinder@latest
go install -v github.com/tomnomnom/httprobe@latest
go install -v github.com/tomnomnom/waybackurls@latest
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go install -v github.com/michenriksen/aquatone@latest


# Add to PATH
echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
source ~/.bashrc

echo -e "\n\033[1;32m[✓] Installation complete! Run './reconghost.sh -h' for usage.\033[0m"
#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "The OS release is: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && exit 1 ;;
    esac
}
ARCH=$(arch)
echo "Arch: $ARCH"

check_glibc_version() {
    glibc_version=$(ldd --version | head -n1 | awk '{print $NF}')
    required_version="2.32"
    if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
        echo -e "${red}GLIBC version $glibc_version is too old! Required: 2.32 or higher${plain}"
        exit 1
    fi
    echo "GLIBC version: $glibc_version (meets requirement of 2.32+)"
}
check_glibc_version

install_base() {
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -y wget curl tar tzdata
        ;;
    centos | almalinux | rocky | ol)
        yum -y update && yum install -y wget curl tar tzdata
        ;;
    fedora | amzn | virtuozzo)
        dnf -y update && dnf install -y wget curl tar tzdata
        ;;
    *)
        apt-get update && apt install -y wget curl tar tzdata
        ;;
    esac
}

echo -e "${green}Running...${plain}"
install_base

echo -e "${green}Downloading your custom x-ui package...${plain}"

cd /usr/local/
systemctl stop x-ui 2>/dev/null
rm -rf /usr/local/x-ui

wget -O x-ui-linux-amd64.tar.gz "https://raw.githubusercontent.com/LLPlayUp/p-3x-ui/main/x-ui-linux-amd64.tar.gz"
if [[ $? -ne 0 ]]; then
    echo -e "${red}Download failed. Please check your link!${plain}"
    exit 1
fi

tar zxvf x-ui-linux-amd64.tar.gz
rm -f x-ui-linux-amd64.tar.gz

cd x-ui
chmod +x x-ui
chmod +x bin/xray-linux-amd64

cp -f x-ui.service /etc/systemd/system/
wget -O /usr/bin/x-ui https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
chmod +x /usr/local/x-ui/x-ui.sh
chmod +x /usr/bin/x-ui

systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

echo -e "${green}Your custom x-ui installation finished, it is running now...${plain}"
echo -e "Access the panel at: http://<your-ip>:2053 (default)"
echo -e "Use the 'x-ui' command to manage the panel."

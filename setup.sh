#!/bin/bash
#
# PeyxDev Auto Installer
# Fixed for Debian 13 with Safety Features
#

sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"

# Color definitions
green="\e[38;5;82m"
red="\e[38;5;196m"
neutral="\e[0m"
orange="\e[38;5;130m"
blue="\e[38;5;39m"
yellow="\e[38;5;226m"
purple="\e[38;5;141m"
bold_white="\e[1;37m"
pink="\e[38;5;205m"
reset="\e[0m"
gray="\e[38;5;245m"

# Safety checks
function safety_check() {
    echo -e "${yellow}Melakukan safety check...${neutral}"
    
    # Check available memory
    MEM_AVAILABLE=$(free -m | awk 'NR==2{print $7}')
    if [ "$MEM_AVAILABLE" -lt 200 ]; then
        echo -e "${red}Warning: Memory available hanya ${MEM_AVAILABLE}MB, disarankan minimal 200MB${neutral}"
        echo -e "${yellow}Lanjutkan? (y/n): ${neutral}"
        read -r answer
        if [ "$answer" != "y" ]; then
            exit 1
        fi
    fi
    
    # Check disk space
    DISK_AVAILABLE=$(df / | awk 'NR==2{print $4}')
    if [ "$DISK_AVAILABLE" -lt 1048576 ]; then
        echo -e "${red}Warning: Disk space rendah, mungkin menyebabkan masalah${neutral}"
    fi
    
    # Check internet connectivity
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        echo -e "${red}Error: Tidak ada koneksi internet${neutral}"
        exit 1
    fi
}

function cleanup_on_failure() {
    echo -e "${red}Cleanup on failure...${neutral}"
    # Restore original resolv.conf if exists
    if [ -f /etc/resolv.conf.bak ]; then
        cp /etc/resolv.conf.bak /etc/resolv.conf
    fi
    
    # Reset sysctl to safe values
    sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
    sysctl -p >/dev/null 2>&1
    
    echo -e "${yellow}System restored to safe state${neutral}"
}

# Spinner definitions
SPINNER=("⣷" "⣯" "⣟" "⡿" "⢿" "⣻" "⣽" "⣾")

function spinner() {
    while true; do
        for i in "${SPINNER[@]}"; do
            echo -ne "\r$1 ${yellow}$i${neutral} "
            sleep 0.1
        done
    done
}

function run_with_spinner() {
    local msg="$1"
    shift
    local cmd=("$@")
    
    # Start spinner
    spinner "$msg" &
    local spinner_pid=$!
    
    # Execute command with timeout
    timeout 300 "${cmd[@]}" >/dev/null 2>&1
    
    local exit_code=$?
    
    # Kill spinner
    kill $spinner_pid 2>/dev/null
    wait $spinner_pid 2>/dev/null
    
    # Clear spinner line
    echo -ne "\r\033[K"
    
    if [ $exit_code -eq 0 ]; then
        echo -e "\r$msg ${green}✓${neutral}"
    elif [ $exit_code -eq 124 ]; then
        echo -e "\r$msg ${red}✗ (Timeout)${neutral}"
    else
        echo -e "\r$msg ${red}✗ (Error: $exit_code)${neutral}"
    fi
    
    return $exit_code
}

function CEKIP () {
    MYIP=$(curl -sS ipv4.icanhazip.com)
    IPVPS=$(curl -sS https://raw.githubusercontent.com/PeyxDev/esce/main/ipx | grep $MYIP | awk '{print $4}')
    if [[ $MYIP == $IPVPS ]]; then
        domain
        Pasang
    else
        domain
        Pasang
    fi
}

clear
NC='\033[0m'
purple() { echo -e "\\033[35;1m${*}\\033[0m"; }
tyblue() { echo -e "\\033[36;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

cd /root
if [ "${EUID}" -ne 0 ]; then
    echo "You need to run this script as root"
    exit 1
fi

if [ "$(systemd-detect-virt)" == "openvz" ]; then
    echo "OpenVZ is not supported"
    exit 1
fi

# Safety check first
safety_check

# Check Debian version
DEBIAN_VERSION=$(cat /etc/debian_version 2>/dev/null | cut -d'.' -f1)
if [[ $DEBIAN_VERSION -ge 12 ]]; then
    echo -e "${yellow}Debian ${DEBIAN_VERSION} detected - applying compatibility fixes...${neutral}"
fi

localip=$(hostname -I | cut -d\  -f1)
hst=( `hostname` )
dart=$(cat /etc/hosts | grep -w `hostname` | awk '{print $2}')
if [[ "$hst" != "$dart" ]]; then
    echo "$localip $(hostname)" >> /etc/hosts
fi

# Backup original resolv.conf
cp /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null || true

secs_to_human() {
    echo "Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minute's $(( ${1} % 60 )) seconds"
}

mkdir -p /etc/xray
mkdir -p /var/lib/ >/dev/null 2>&1
echo "IP=" >> /var/lib/ipvps.conf

clear
echo -e "${blue} ┌───────────────────────────────────────────────┐${neutral}"
echo -e "${blue} │                   ${bold_white}PeyxDev${neutral}                     ${blue}│${neutral}"
echo -e "${blue} │         ${green}┌─┐┬ ┬┌┬┐┌─┐┌─┐┌─┐┬─┐┬┌─┐┌┬┐          ${blue}│${neutral}"
echo -e "${blue} │         ${green}├─┤│ │ │ │ │└─┐│  ├┬┘│├─┘ │           ${blue}│${neutral}"
echo -e "${blue} │         ${green}┴ ┴└─┘ ┴ └─┘└─┘└─┘┴└─┴┴   ┴           ${neutral}${blue}│${neutral}"
echo -e "${blue} │         ${yellow}Copyright${reset} (C)${gray} https://t.me/frel01     ${blue}│${neutral}"
echo -e "${blue} └───────────────────────────────────────────────┘${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${yellow}     Masukkan Nama Anda untuk memulai instalasi:${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo " "

until [[ $name =~ ^[a-zA-Z0-9_.-]+$ ]]; do
    read -rp "   Masukan Nama Kamu Disini tanpa spasi : " -e name
done

echo "PeyxDev" > /etc/xray/username
echo ""
clear
author=$name
echo ""
echo ""

function update_system() {
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}         UPDATING SYSTEM DEBIAN ${DEBIAN_VERSION}${neutral}    ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    
    run_with_spinner "Memperbarui package list..." apt update
    
    # Fix for Debian 13 - install keyring first
    if [[ $DEBIAN_VERSION -ge 12 ]]; then
        run_with_spinner "Menginstall debian-archive-keyring..." apt install -y debian-archive-keyring
        run_with_spinner "Menginstall apt-transport-https..." apt install -y apt-transport-https ca-certificates
    fi
    
    run_with_spinner "Mengupgrade system..." apt upgrade -y
    run_with_spinner "Menginstall package dasar..." apt install -y curl wget sudo gnupg
}

function key2(){
    [[ ! -f /usr/bin/git ]] && apt install git -y &> /dev/null
    clear
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}               IZIN SSHWS${neutral}                 ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    
    MYIP=$(curl -sS ipv4.icanhazip.com)
    if [[ ! -d /etc/github ]]; then
        mkdir -p /etc/github
    fi
    
    run_with_spinner "Mengambil data GitHub..." curl -s https://v4.serverpremium.web.id:81/token -o /etc/github/api
    run_with_spinner "Mengambil email..." curl -s https://v4.serverpremium.web.id:81/email -o /etc/github/email
    run_with_spinner "Mengambil username..." curl -s https://v4.serverpremium.web.id:81/nama -o /etc/github/username
    
    clear
    APIGIT=$(cat /etc/github/api)
    EMAILGIT=$(cat /etc/github/email)
    USERGIT=$(cat /etc/github/username)
    hhari=$(date -d "999 days" +"%Y-%m-%d")
    
    cd
    run_with_spinner "Mengkloning repository izin..." git clone https://github.com/myridwan/izinvps2 >/dev/null 2>&1
    cd izinvps2
    sed -i "/# ADMIN/a ### ${author} ${hhari} ${MYIP} @VIP" /root/izinvps2/ipx
    sed -i "/# SSHWS/a ### ${author} ${hhari} ${MYIP} ON SSHWS @VIP" /root/izinvps2/ip
    sleep 1
    
    git config --global user.email "${EMAILGIT}" >/dev/null 2>&1
    git config --global user.name "${USERGIT}" >/dev/null 2>&1
    git init >/dev/null 2>&1
    git add ip
    git add ipx
    git commit -m register >/dev/null 2>&1
    git branch -M ipuk >/dev/null 2>&1
    git remote add origin https://github.com/${USERGIT}/izinvps >/dev/null 2>&1
    
    run_with_spinner "Mengupload data izin..." git push -f https://${APIGIT}@github.com/${USERGIT}/izinvps >/dev/null 2>&1
    
    sleep 1
    cd
    rm -rf /root/izinvps2
    clear
}

function domain(){
    fun_bar() {
        CMD[0]="$1"
        CMD[1]="$2"
        (
            [[ -e $HOME/fim ]] && rm $HOME/fim
            ${CMD[0]} -y >/dev/null 2>&1
            ${CMD[1]} -y >/dev/null 2>&1
            touch $HOME/fim
        ) >/dev/null 2>&1 &
        
        tput civis
        echo -ne "  ${yellow}Update Domain..${neutral} ${bold_white}-${neutral} ${yellow}[${neutral}"
        while true; do
            for ((i = 0; i < 18; i++)); do
                echo -ne "${green}#${neutral}"
                sleep 0.1s
            done
            [[ -e $HOME/fim ]] && rm $HOME/fim && break
            echo -e "${yellow}]${neutral}"
            sleep 1s
            tput cuu1
            tput dl1
            echo -ne "  ${yellow}Update Domain...${neutral} ${bold_white}-${neutral} ${yellow}[${neutral}"
        done
        echo -e "${yellow}]${bold_white} -${green} Succes !${bold_white}"
        tput cnorm
    }
    
    res1() {
        wget ${REPO}install/pointing.sh && chmod +x pointing.sh && ./pointing.sh
        clear
    }
    
    clear
    cd
    echo -e "${green}━━━━━━━━━━┏┓━━━━━━━━━━━━━━━━━━━━━━━━┏┓━━━━━━━━━━━${NC}"
    echo -e "${green}━━━━━━━━━┏┛┗┓━━━━━━━━━━━━━━━━━━━━━━┏┛┗┓━━━━━━━━━━${NC}"
    echo -e "${green}┏━━┓━┏┓┏┓┗┓┏┛┏━━┓━━━━┏━━┓┏━━┓┏┓┏━┓━┗┓┏┛┏┓┏━┓━┏━━┓${NC}"
    echo -e "${green}┗━┓┃━┃┃┃┃━┃┃━┃┏┓┃━━━━┃┏┓┃┃┏┓┃┣┫┃┏┓┓━┃┃━┣┫┃┏┓┓┃┏┓┃${NC}"
    echo -e "${green}┃┗┛┗┓┃┗┛┃━┃┗┓┃┗┛┃━━━━┃┗┛┃┃┗┛┃┃┃┃┃┃┃━┃┗┓┃┃┃┃┃┃┃┗┛┃${NC}"
    echo -e "${green}┗━━━┛┗━━┛━┗━┛┗━━┛━━━━┃┏━┛┗━━┛┗┛┗┛┗┛━┗━┛┗┛┗┛┗┛┗━┓┃${NC}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━┏━┛┃${NC}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━┗━━┛${NC}"
    echo -e "${blue}                     SETUP DOMAIN VPS     ${NC}"
    echo -e "${orange}----------------------------------------------------------${NC}"
    echo -e "${green} 1. Use Domain Random / Gunakan Domain Sendiri ${NC}"
    echo -e "${green} 2. Choose Your Own Domain / Gunakan Domain Random ${NC}"
    echo -e "${orange}----------------------------------------------------------${NC}"
    
    until [[ $domain =~ ^[12]+$ ]]; do
        read -p "   Please select numbers 1 atau 2 : " domain
    done
    
    if [[ $domain == "1" ]]; then
        clear
        echo -e "${green}┌──────────────────────────────────────────┐${NC}"
        echo -e "${green}│${bold_white}              TERIMA KASIH${neutral}                ${green}│${NC}"
        echo -e "${green}│${bold_white}         SUDAH MENGGUNAKAN SCRIPT${neutral}         ${green}│${NC}"
        echo -e "${green}│${bold_white}             PEYX TUNNELING${neutral}               ${green}│${NC}"
        echo -e "${green}└──────────────────────────────────────────┘${NC}"
        echo " "
        
        until [[ $dnss =~ ^[a-zA-Z0-9_.-]+$ ]]; do
            read -rp "Masukan domain kamu Disini : " -e dnss
        done
        
        rm -rf /etc/v2ray
        rm -rf /etc/nsdomain
        rm -rf /etc/per
        mkdir -p /etc/xray
        mkdir -p /etc/v2ray
        mkdir -p /etc/nsdomain
        touch /etc/xray/domain
        touch /etc/v2ray/domain
        touch /etc/xray/slwdomain
        touch /etc/v2ray/scdomain
        echo "$dnss" > /root/domain
        echo "$dnss" > /root/scdomain
        echo "$dnss" > /etc/xray/scdomain
        echo "$dnss" > /etc/v2ray/scdomain
        echo "$dnss" > /etc/xray/domain
        echo "$dnss" > /etc/v2ray/domain
        echo "IP=$dnss" > /var/lib/ipvps.conf
        
        # Konfirmasi domain tersimpan - FIXED TIDAK GESER
        domain_display="$dnss"
        if [ ${#domain_display} -gt 30 ]; then
            domain_display="${domain_display:0:27}..."
        fi
        
        echo -e "${green}┌──────────────────────────────────────────┐${NC}"
        echo -e "${green}│${bold_white}           DOMAIN BERHASIL DISIMPAN${neutral}       ${green}│${NC}"
        printf "${green}│${bold_white} %-40s ${green}│${NC}\n" "Domain: $domain_display"
        echo -e "${green}│${bold_white}                                          ${green}│${NC}"
        echo -e "${green}│${bold_white}   Domain telah tersimpan di lokasi:${neutral}      ${green}│${NC}"
        echo -e "${green}│${bold_white}   - /root/domain${neutral}                         ${green}│${NC}"
        echo -e "${green}│${bold_white}   - /etc/xray/domain${neutral}                     ${green}│${NC}"
        echo -e "${green}│${bold_white}   - /etc/v2ray/domain${neutral}                    ${green}│${NC}"
        echo -e "${green}│${bold_white}   - /var/lib/ipvps.conf${neutral}                  ${green}│${NC}"
        echo -e "${green}└──────────────────────────────────────────┘${NC}"
        echo ""
        read -p "Tekan Enter untuk melanjutkan..."
        clear
    fi
    
    if [[ $domain == "2" ]]; then
        clear
        echo -e "${green}┌──────────────────────────────────────────┐${NC}"
        echo -e "${green}│${bold_white}         Contoh subdomain ( xxx )${neutral}         ${green}│${NC}"
        echo -e "${green}│${bold_white}    xxx.peyx.site jadi subdomain kamu${neutral}     ${green}│${NC}"
        echo -e "${green}└──────────────────────────────────────────┘${NC}"
        echo " "
        
        until [[ $dn1 =~ ^[a-zA-Z0-9_.-]+$ ]]; do
            read -rp "Masukan subdomain kamu Disini tanpa spasi : " -e dn1
        done
        
        rm -rf /etc/v2ray
        rm -rf /etc/nsdomain
        rm -rf /etc/per
        mkdir -p /etc/xray
        mkdir -p /etc/v2ray
        mkdir -p /etc/nsdomain
        touch /etc/xray/domain
        touch /etc/v2ray/domain
        touch /etc/xray/slwdomain
        touch /etc/v2ray/scdomain
        echo "$dn1" > /root/domain
        echo "$dn1" > /root/scdomain
        echo "$dn1" > /etc/xray/scdomain
        echo "$dn1" > /etc/v2ray/scdomain
        echo "$dn1" > /etc/xray/domain
        echo "$dn1" > /etc/v2ray/domain
        echo "IP=$dn1" > /var/lib/ipvps.conf
        
        # Konfirmasi domain tersimpan - FIXED TIDAK GESER
        domain_display="$dn1"
        if [ ${#domain_display} -gt 30 ]; then
            domain_display="${domain_display:0:27}..."
        fi
        
        echo -e "${green}┌──────────────────────────────────────────┐${NC}"
        echo -e "${green}│${bold_white}           DOMAIN BERHASIL DISIMPAN${neutral}       ${green}│${NC}"
        printf "${green}│${bold_white} %-40s ${green}│${NC}\n" "Domain: $domain_display"
        echo -e "${green}│${bold_white}                                          ${green}│${NC}"
        echo -e "${green}│${bold_white}   Domain telah tersimpan di lokasi:${neutral}      ${green}│${NC}"
        echo -e "${green}│${bold_white}   - /root/domain${neutral}                         ${green}│${NC}"
        echo -e "${green}│${bold_white}   - /etc/xray/domain${neutral}                     ${green}│${NC}"
        echo -e "${green}│${bold_white}   - /etc/v2ray/domain${neutral}                    ${green}│${NC}"
        echo -e "${green}│${bold_white}   - /var/lib/ipvps.conf${neutral}                  ${green}│${NC}"
        echo -e "${green}└──────────────────────────────────────────┘${NC}"
        echo ""
        read -p "Tekan Enter untuk melanjutkan..."
        clear
        
        cd
        sleep 1
        fun_bar 'res1'
        clear
        rm /root/subdomainx
    fi
}

function Pasang(){
    cd
    run_with_spinner "Mengunduh tools..." wget ${REPO}tools.sh -O tools.sh
    chmod +x tools.sh
    bash tools.sh
    clear
    start=$(date +%s)
    ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
    
    # Update system first for Debian 13 compatibility
    update_system
    
    run_with_spinner "Menginstall git dan curl..." apt install git curl -y
    run_with_spinner "Menginstall python..." apt install python -y
    
    # Fix for Debian 13 - install python3 if python not available
    if ! command -v python &> /dev/null; then
        run_with_spinner "Menginstall python3..." apt install python3 -y
        ln -sf /usr/bin/python3 /usr/bin/python
    fi
}

function Installasi(){
    fun_bar() {
        CMD[0]="$1"
        CMD[1]="$2"
        (
            [[ -e $HOME/fim ]] && rm -f $HOME/fim
            ${CMD[0]} -y >/dev/null 2>&1
            ${CMD[1]} -y >/dev/null 2>&1
            touch $HOME/fim
        ) >/dev/null 2>&1 &
        
        tput civis
        echo -ne "  ${yellow}Lagi Menginstal File${neutral} ${bold_white}-${neutral} ${yellow}[${neutral}"
        while true; do
            for ((i = 0; i < 18; i++)); do
                echo -ne "${green}#${neutral}"
                sleep 0.1
            done
            if [[ -e $HOME/fim ]]; then
                rm -f $HOME/fim
                break
            fi
            echo -e "${yellow}]${neutral}"
            sleep 1
            tput cuu1
            tput dl1
            echo -ne "  ${yellow}Lagi Menginstal File${neutral} ${bold_white}-${neutral} ${yellow}[${neutral}"
        done
        echo -e "${yellow}]${bold_white} -${green} Succes !${bold_white}"
        tput cnorm
    }
    
    res2() {
        if run_with_spinner "Menginstall SSH & OpenVPN..." wget ${REPO}install/ssh-vpn.sh -O ssh-vpn.sh && chmod +x ssh-vpn.sh && timeout 600 ./ssh-vpn.sh; then
            echo -e "${green}SSH & OpenVPN installed successfully${neutral}"
        else
            echo -e "${red}SSH & OpenVPN installation had issues, continuing...${neutral}"
        fi
        clear
    }
    
    res3() {
        if run_with_spinner "Menginstall Xray..." wget ${REPO}install/ins-xray.sh -O ins-xray.sh && chmod +x ins-xray.sh && timeout 600 ./ins-xray.sh; then
            echo -e "${green}Xray installed successfully${neutral}"
        else
            echo -e "${red}Xray installation had issues, continuing...${neutral}"
        fi
        clear
    }
    
    res4() {
        if run_with_spinner "Menginstall WebSocket SSH..." wget ${REPO}sshws/insshws.sh -O insshws.sh && chmod +x insshws.sh && timeout 300 ./insshws.sh; then
            echo -e "${green}WebSocket SSH installed successfully${neutral}"
        else
            echo -e "${red}WebSocket SSH installation had issues, continuing...${neutral}"
        fi
        clear
    }
    
    res5() {
        run_with_spinner "Menginstall Backup Menu..." wget ${REPO}install/set-br.sh -O set-br.sh && chmod +x set-br.sh && ./set-br.sh
        clear
    }
    
    res6() {
        run_with_spinner "Menginstall OHP..." wget ${REPO}sshws/ohp.sh -O ohp.sh && chmod +x ohp.sh && ./ohp.sh
        clear
    }
    
    res7() {
        run_with_spinner "Mengunduh Extra Menu..." wget ${REPO}menu/update.sh -O update.sh && chmod +x update.sh && ./update.sh
        clear
    }
    
    res8() {
        if run_with_spinner "Menginstall SlowDNS..." wget ${REPO}slowdns/installsl.sh -O installsl.sh && chmod +x installsl.sh && timeout 300 bash installsl.sh; then
            echo -e "${green}SlowDNS installed successfully${neutral}"
        else
            echo -e "${red}SlowDNS installation had issues, continuing...${neutral}"
        fi
        clear
    }
    
    res9() {
        if run_with_spinner "Menginstall UDP Custom..." wget ${REPO}install/udp-custom.sh -O udp-custom.sh && chmod +x udp-custom.sh && timeout 300 bash udp-custom.sh; then
            echo -e "${green}UDP Custom installed successfully${neutral}"
        else
            echo -e "${red}UDP Custom installation had issues, continuing...${neutral}"
        fi
        clear
    }
    
    # Fix for Debian 13 detection
    OS_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    OS_VERSION=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    
    if [[ $OS_ID == "ubuntu" ]]; then
        echo -e "${green}Setup nginx For OS Is $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${NC}"
        setup_ubuntu
    elif [[ $OS_ID == "debian" ]]; then
        echo -e "${green}Setup nginx For OS Is $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${NC}"
        echo -e "${yellow}Debian Version: ${OS_VERSION}${NC}"
        setup_debian
    else
        echo -e " Your OS Is Not Supported ( ${YELLOW}$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${FONT} )"
    fi
}

function setup_debian(){
    # Additional fixes for Debian 13
    if [[ $DEBIAN_VERSION -ge 12 ]]; then
        echo -e "${yellow}Menerapkan safety measures untuk Debian ${DEBIAN_VERSION}...${neutral}"
        
        # Install minimal dependencies only
        run_with_spinner "Menginstall dependencies minimal..." apt install -y dirmngr gnupg2
        
        # Skip problematic nginx repo for stability
        echo -e "${yellow}Menggunakan nginx dari repository default untuk stabilitas...${neutral}"
    fi
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}      PROCESS INSTALLED SSH & OPENVPN${neutral}     ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res2'
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}           PROCESS INSTALLED XRAY${neutral}         ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res3'
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}       PROCESS INSTALLED WEBSOCKET SSH${neutral}    ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res4'
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}       PROCESS INSTALLED BACKUP MENU${neutral}      ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res5'
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}           PROCESS INSTALLED OHP${neutral}          ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res6'
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}           DOWNLOAD EXTRA MENU${neutral}            ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res7'
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}           DOWNLOAD SYSTEM${neutral}                ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res8'
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}           DOWNLOAD UDP COSTUM${neutral}            ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res9'
}

function setup_ubuntu(){
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}      PROCESS INSTALLED SSH & OPENVPN${neutral}     ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res2
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}           PROCESS INSTALLED XRAY${neutral}         ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res3
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}       PROCESS INSTALLED WEBSOCKET SSH${neutral}    ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res4
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}       PROCESS INSTALLED BACKUP MENU${neutral}      ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res5
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}           PROCESS INSTALLED OHP${neutral}          ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res6
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}           DOWNLOAD EXTRA MENU${neutral}            ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res7
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}           DOWNLOAD SYSTEM${neutral}                ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res8
    
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}           DOWNLOAD UDP COSTUM${neutral}            ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res9
}

function iinfo(){
    domain=$(cat /etc/xray/domain)
    TIMES="10"
    CHATID="7661292905"
    KEY="7916829256:AAHB-_Jv24fTQfR98HA6eNogR8zzYzChw6g"
    URL="https://api.telegram.org/bot$KEY/sendMessage"
    ISP=$(cat /etc/xray/isp)
    CITY=$(cat /etc/xray/city)
    domain=$(cat /etc/xray/domain)
    TIME=$(date +'%Y-%m-%d %H:%M:%S')
    RAMMS=$(free -m | awk 'NR==2 {print $2}')
    MODEL2=$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')
    MYIP=$(curl -sS ipv4.icanhazip.com)
    IZIN=$(curl -sS https://raw.githubusercontent.com/PeyxDev/esce/main/ipx | grep $MYIP | awk '{print $3}' )
    d1=$(date -d "$IZIN" +%s)
    d2=$(date -d "$today" +%s)
    EXP=$(( (d1 - d2) / 86400 ))
    TEXT="
<code>━━━━━━━━━━━━━━━━━━━━</code>
<code>⚠️ PEYX AUTOSCRIPT PREMIUM ⚠️</code>
<code>━━━━━━━━━━━━━━━━━━━━</code>
<code>NAME : </code><code>${author}</code>
<code>TIME : </code><code>${TIME} WIB</code>
<code>DOMAIN : </code><code>${domain}</code>
<code>IP : </code><code>${MYIP}</code>
<code>ISP : </code><code>${ISP} $CITY</code>
<code>OS LINUX : </code><code>${MODEL2}</code>
<code>RAM : </code><code>${RAMMS} MB</code>
<code>EXP SCRIPT : </code><code>$EXP Days</code>
<code>━━━━━━━━━━━━━━━━━━━━</code>
<i> Notifikasi Installer Script...</i>
"'&reply_markup={"inline_keyboard":[[{"text":"🔥ᴏʀᴅᴇʀ","url":"https://t.me/frel01"},{"text":"🔥GRUP","url":"https://t.me/pxstoree"}]]}'
    curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
    clear
}

NEW_FILE_MAX=65535
NF_CONNTRACK_MAX="net.netfilter.nf_conntrack_max=262144"
NF_CONNTRACK_TIMEOUT="net.netfilter.nf_conntrack_tcp_timeout_time_wait=30"
SYSCTL_CONF="/etc/sysctl.conf"
CURRENT_FILE_MAX=$(grep "^fs.file-max" "$SYSCTL_CONF" | awk '{print $3}' 2>/dev/null)

if [ "$CURRENT_FILE_MAX" != "$NEW_FILE_MAX" ]; then
    if grep -q "^fs.file-max" "$SYSCTL_CONF"; then
        sed -i "s/^fs.file-max.*/fs.file-max = $NEW_FILE_MAX/" "$SYSCTL_CONF" >/dev/null 2>&1
    else
        echo "fs.file-max = $NEW_FILE_MAX" >> "$SYSCTL_CONF" 2>/dev/null
    fi
fi

if ! grep -q "^net.netfilter.nf_conntrack_max" "$SYSCTL_CONF"; then
    echo "$NF_CONNTRACK_MAX" >> "$SYSCTL_CONF" 2>/dev/null
fi

if ! grep -q "^net.netfilter.nf_conntrack_tcp_timeout_time_wait" "$SYSCTL_CONF"; then
    echo "$NF_CONNTRACK_TIMEOUT" >> "$SYSCTL_CONF" 2>/dev/null
fi

sysctl -p >/dev/null 2>&1

key2
CEKIP
Installasi

# FIXED SYSTEMD-RESOLVED SECTION - More safe approach
echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│${bold_white}        CONFIGURING DNS RESOLVER${neutral}        ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"

# Safe DNS configuration
if [ -f /etc/resolv.conf ]; then
    run_with_spinner "Backup resolv.conf..." cp /etc/resolv.conf /etc/resolv.conf.backup.script
fi

# Configure DNS manually - don't make immutable immediately
run_with_spinner "Mengatur DNS manual..." bash -c 'echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 1.1.1.1" > /etc/resolv.conf'

# Test DNS first before making immutable
if nslookup google.com >/dev/null 2>&1; then
    run_with_spinner "DNS working, locking configuration..." chattr +i /etc/resolv.conf
else
    echo -e "${yellow}DNS test failed, skipping immutable attribute${neutral}"
    # Restore backup if DNS test fails
    if [ -f /etc/resolv.conf.backup.script ]; then
        cp /etc/resolv.conf.backup.script /etc/resolv.conf
    fi
fi

cat> /root/.profile << END
if [ "$BASH" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi
mesg n || true
clear
welcome
END

chmod 644 /root/.profile

if [ -f "/root/log-install.txt" ]; then
    rm /root/log-install.txt > /dev/null 2>&1
fi

if [ -f "/etc/afak.conf" ]; then
    rm /etc/afak.conf > /dev/null 2>&1
fi

history -c
serverV=$( curl -sS ${REPO}versi  )
echo $serverV > /opt/.ver
echo "00" > /home/daily_reboot
aureb=$(cat /home/daily_reboot)
b=11
if [ $aureb -gt $b ]
then
    gg="PM"
else
    gg="AM"
fi

cd
curl -sS ifconfig.me > /etc/myipvps
curl -s ipinfo.io/city?token=75082b4831f909 >> /etc/xray/city
curl -s ipinfo.io/org?token=75082b4831f909  | cut -d " " -f 2-10 >> /etc/xray/isp

# Clean up files
run_with_spinner "Membersihkan file sementara..." rm -f /root/tools.sh /root/setup.sh /root/pointing.sh /root/ssh-vpn.sh /root/ins-xray.sh /root/insshws.sh /root/set-br.sh /root/ohp.sh /root/update.sh /root/installsl.sh /root/udp-custom.sh

secs_to_human "$(($(date +%s) - ${start}))" | tee -a log-install.txt
sleep 3
echo ""
cd
iinfo

# Final safety check
echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│${bold_white}           FINAL SAFETY CHECK${neutral}           ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"

# Check critical services
if systemctl is-active --quiet ssh; then
    echo -e "${green}✓ SSH service is running${neutral}"
else
    echo -e "${red}✗ SSH service is not running${neutral}"
    echo -e "${yellow}Mencoba restart SSH...${neutral}"
    systemctl restart ssh
fi

# Check network
if ping -c 1 8.8.8.8 &>/dev/null; then
    echo -e "${green}✓ Network connectivity OK${neutral}"
else
    echo -e "${red}✗ No network connectivity${neutral}"
fi

# Check memory
MEM_USED=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
echo -e "${yellow}Memory usage: ${MEM_USED}${neutral}"

# Check failed services
FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)
if [ "$FAILED_SERVICES" -gt 0 ]; then
    echo -e "${red}⚠️  $FAILED_SERVICES services failed${neutral}"
    systemctl --failed --no-legend
else
    echo -e "${green}✓ All services running properly${neutral}"
fi

echo -e "${green}Installation completed with safety checks${neutral}"

echo -e "${green}┌────────────────────────────────────────────┐${NC}"
echo -e "${green}│${bold_white}  INSTALL SCRIPT SELESAI..${neutral}                  ${green}│${NC}"
echo -e "${green}└────────────────────────────────────────────┘${NC}"
echo ""
sleep 4

echo -e "[ ${yellow}WARNING${NC} ] Do you want to reboot now ? (y/n)? "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
    echo -e "${yellow}Reboot dibatalkan. System tetap berjalan.${neutral}"
    exit 0
else
    echo -e "${yellow}Rebooting system...${neutral}"
    sleep 2
    reboot
fi

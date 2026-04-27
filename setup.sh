#!/bin/bash

# ==================== KONFIGURASI AWAL ====================
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"

# ==================== KONFIGURASI PASSWORD IZIN ====================
# Ganti password ini sesuai keinginan Anda
# INSTALL_PASSWORD="PeyxDev2024"
# Atau bisa juga ambil dari server cloud:
INSTALL_PASSWORD=$(curl -s https://pxstore.web.id/password 2>/dev/null)

# ==================== WARNA MODERN ====================
REDBLD="\033[0m\033[91;1m"
Green="\e[92;1m"
RED="\033[1;31m"
YELLOW="\033[33;1m"
BLUE="\033[36;1m"
FONT="\033[0m"
GREENBG="\033[42;37m"
REDBG="\033[41;37m"
NC='\e[0m'
CYAN="\033[96;1m"
WHITE="\033[97;1m"
GRAY="\033[1;30m"

neutral="${NC}"
orange="\e[38;5;130m"
purple="\e[38;5;141m"
bold_white="\e[1;37m"
pink="\e[38;5;205m"
reset="\e[0m"
green="\e[38;5;82m"
red="\e[38;5;196m"
blue="\e[38;5;39m"
yellow="\e[38;5;226m"
gray="\e[38;5;245m"

# Warna modern untuk efek
MODERN_CYAN="\033[38;2;0;255;255m"
MODERN_PURPLE="\033[38;2;156;0;255m"
MODERN_GREEN="\033[38;2;0;255;128m"
MODERN_RED="\033[38;2;255;50;50m"
MODERN_ORANGE="\033[38;2;255;128;0m"
MODERN_DIM="\033[2m"
MODERN_BOLD="\033[1m"
RESET_ALL="\033[0m"

# Animasi characters
SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
CHECK_ICON="✓"
CROSS_ICON="✗"

# ==================== FUNGSI MODERN LOADING ====================

show_loading_animation() {
    local pid=$1
    local message=$2
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r${MODERN_CYAN}${SPINNER[$i]}${RESET_ALL} ${MODERN_DIM}${message}...${RESET_ALL}"
        i=$(( (i+1) % 10 ))
        sleep 0.1
    done
    printf "\r\033[K"
}

run_task() {
    local message="$1"
    local command="$2"
    
    printf "${MODERN_CYAN}◐${RESET_ALL} ${MODERN_DIM}${message}...${RESET_ALL}"
    
    bash -c "$command" &>/tmp/install.log &
    local task_pid=$!
    
    show_loading_animation $task_pid "$message"
    wait $task_pid
    
    if [ $? -eq 0 ]; then
        printf "\r${MODERN_GREEN}${CHECK_ICON}${RESET_ALL} ${MODERN_BOLD}${message}${RESET_ALL} ${MODERN_GREEN}${CHECK_ICON}${RESET_ALL}\n"
        return 0
    else
        printf "\r${MODERN_RED}${CROSS_ICON}${RESET_ALL} ${MODERN_BOLD}${message}${RESET_ALL} ${MODERN_RED}${CROSS_ICON}${RESET_ALL}\n"
        return 1
    fi
}

print_section_header() {
    local title="$1"
    echo ""
    echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
    echo -e "${MODERN_BOLD}${WHITE}  ${title}${RESET_ALL}"
    echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
}

print_success() {
    echo -e "${MODERN_GREEN}  ${CHECK_ICON}${RESET_ALL} ${MODERN_BOLD}$1${RESET_ALL}"
}

print_error() {
    echo -e "${MODERN_RED}  ${CROSS_ICON}${RESET_ALL} ${MODERN_BOLD}$1${RESET_ALL}"
}

print_info() {
    echo -e "${MODERN_CYAN}  •${RESET_ALL} $1"
}

print_warning() {
    echo -e "${MODERN_ORANGE}  ⚠${RESET_ALL} ${MODERN_BOLD}$1${RESET_ALL}"
}

# ==================== FUNGSI VERIFIKASI PASSWORD ====================
verify_install_password() {
    local MAX_ATTEMPTS=3
    local attempt=1
    
    clear
    echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
    echo -e "${MODERN_BOLD}${WHITE}              🔐 VERIFIKASI PASSWORD              ${RESET_ALL}"
    echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
    echo ""
    echo -e "  ${MODERN_DIM}Instalasi script ini dilindungi password${RESET_ALL}"
    echo -e "  ${MODERN_DIM}Silakan masukkan password untuk melanjutkan${RESET_ALL}"
    echo ""
    
    while [[ $attempt -le $MAX_ATTEMPTS ]]; do
        echo -ne "  ${MODERN_CYAN}Password${RESET_ALL} ${MODERN_DIM}(Attempt ${attempt}/${MAX_ATTEMPTS}):${RESET_ALL} "
        read -s input_password
        echo ""
        
        if [[ "$input_password" == "$INSTALL_PASSWORD" ]]; then
            echo ""
            print_success "Password verified! Melanjutkan instalasi..."
            sleep 1
            return 0
        else
            echo ""
            print_error "Password salah!"
            remaining=$((MAX_ATTEMPTS - attempt))
            if [[ $remaining -gt 0 ]]; then
                print_warning "Kesempatan tersisa: ${remaining}"
                echo ""
            fi
            attempt=$((attempt + 1))
        fi
    done
    
    # Jika gagal 3 kali
    clear
    echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
    echo -e "${MODERN_BOLD}${WHITE}              ⛔ AKSES DITOLAK ⛔              ${RESET_ALL}"
    echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
    echo ""
    echo -e "  ${MODERN_RED}${CROSS_ICON} Anda telah gagal memasukkan password 3 kali${RESET_ALL}"
    echo ""
    echo -e "  ${MODERN_ORANGE}⚠ Silakan hubungi admin untuk mendapatkan password${RESET_ALL}"
    echo ""
    echo -e "  ${MODERN_CYAN}Telegram : https://t.me/PeyxDev${RESET_ALL}"
    echo -e "  ${MODERN_CYAN}Email    : peyxdev@gmail.com${RESET_ALL}"
    echo ""
    echo -e "  ${MODERN_DIM}────────────────────────────────────────────────${RESET_ALL}"
    echo -e "  ${MODERN_DIM}Script by PeyxDev - All rights reserved${RESET_ALL}"
    echo ""
    exit 1
}

# ==================== FUNGSI CEKIP ====================
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
purple() { echo -e "\\033[35;1m${*}\${NC}"; }
tyblue() { echo -e "\\033[36;1m${*}\${NC}"; }
yellow() { echo -e "\\033[33;1m${*}\${NC}"; }
green() { echo -e "\\033[32;1m${*}\${NC}"; }
red() { echo -e "\\033[31;1m${*}\${NC}"; }

cd /root
if [ "${EUID}" -ne 0 ]; then
echo "You need to run this script as root"
exit 1
fi

if [ "$(systemd-detect-virt)" == "openvz" ]; then
echo "OpenVZ is not supported"
exit 1
fi

localip=$(hostname -I | cut -d\  -f1)
hst=( `hostname` )
dart=$(cat /etc/hosts | grep -w `hostname` | awk '{print $2}')
if [[ "$hst" != "$dart" ]]; then
echo "$localip $(hostname)" >> /etc/hosts
fi

secs_to_human() {
echo "Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minute's $(( ${1} % 60 )) seconds"
}

mkdir -p /etc/xray
mkdir -p /var/lib/ >/dev/null 2>&1
echo "IP=" >> /var/lib/ipvps.conf

# ==================== VERIFIKASI PASSWORD SEBELUM INSTALL ====================
verify_install_password

clear
echo -e "${purple} ┌───────────────────────────────────────────────┐${neutral}"
echo -e "${purple} │                   ${bold_white}PeyxDev${neutral}                     ${purple}│${neutral}"
echo -e "${purple} │         ${green}┌─┐┬ ┬┌┬┐┌─┐┌─┐┌─┐┬─┐┬┌─┐┌┬┐          ${purple}│${neutral}"
echo -e "${purple} │         ${green}├─┤│ │ │ │ │└─┐│  ├┬┘│├─┘ │           ${purple}│${neutral}"
echo -e "${purple} │         ${green}┴ ┴└─┘ ┴ └─┘└─┘└─┘┴└─┴┴   ┴           ${neutral}${purple}│${neutral}"
echo -e "${purple} │         ${yellow}Copyright${reset} (C)${gray} https://t.me/PeyxDev    ${purple}│${neutral}"
echo -e "${purple} └───────────────────────────────────────────────┘${neutral}"
echo -e "${purple} ────────────────────────────────────────────────${neutral}"
echo -e "${yellow}     Masukkan Nama Anda untuk memulai instalasi:${neutral}"
echo -e "${purple} ────────────────────────────────────────────────${neutral}"
echo ""

until [[ $name =~ ^[a-zA-Z0-9_.-]+$ ]]; do
read -rp "👉 Masukkan Nama Anda (tanpa spasi): " -e name
done

echo "PeyxDev" > /etc/xray/username
echo ""
clear
author=$name
echo ""
echo ""

# ==================== FUNCTION KEY2 ====================
function key2(){
[[ ! -f /usr/bin/git ]] && run_task "Installing Git" "apt install git -y"

clear
print_section_header "✨ IZIN IP VPS"

MYIP=$(curl -sS ipv4.icanhazip.com)

echo ""
print_section_header "📅 MASA AKTIF SCRIPT"
echo ""
read -p "   Masukkan jumlah hari izin: " custom_days

if ! [[ "$custom_days" =~ ^[0-9]+$ ]]; then
    print_error "Masukkan angka yang valid!"
    sleep 2
    return 1
fi

expired_date=$(date -d "$custom_days days" +"%Y-%m-%d")
expired_date_display=$(date -d "$custom_days days" +"%Y-%m-%d")

echo ""
print_section_header "📋 Ringkasan Izin"
print_info "Nama      : ${author}"
print_info "IP Address: ${MYIP}"
print_info "Masa Aktif: ${custom_days} hari"
print_info "Expired   : ${expired_date_display} (YYYY-MM-DD)"
echo ""

read -p "   Lanjutkan registrasi? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    print_error "Registrasi dibatalkan!"
    sleep 2
    return 0
fi

if [[ ! -d /etc/github ]]; then
mkdir -p /etc/github
fi

run_task "Getting API token" "curl -s http://pxstore.web.id/token > /etc/github/api"
run_task "Getting Email" "curl -s http://pxstore.web.id/email > /etc/github/email"
run_task "Getting Username" "curl -s http://pxstore.web.id/nama > /etc/github/username"

clear
APIGIT=$(cat /etc/github/api)
EMAILGIT=$(cat /etc/github/email)
USERGIT=$(cat /etc/github/username)
cd

run_task "Cloning repository" "git clone https://github.com/peyxdev/esce >/dev/null 2>&1"

cd esce

sed -i "/# ADMIN/a ### ${author} ${expired_date} ${MYIP} @VIP" /root/esce/ipx
sed -i "/# SSHWS/a ### ${author} ${expired_date} ${MYIP} ON SSHWS @VIP" /root/esce/ip

sleep 1
git config --global user.email "${EMAILGIT}" >/dev/null 2>&1
git config --global user.name "${USERGIT}" >/dev/null 2>&1
git init >/dev/null 2>&1
git add ip
git add ipx
git commit -m "register ${author} ${expired_date}" >/dev/null 2>&1
git branch -M main >/dev/null 2>&1
git remote add origin https://github.com/${USERGIT}/esce >/dev/null 2>&1
run_task "Pushing to GitHub" "git push -f https://${APIGIT}@github.com/${USERGIT}/esce >/dev/null 2>&1"

sleep 1
cd
rm -rf /root/esce

echo "${expired_date}" > /etc/xray/expired_date
echo "${author}" > /etc/xray/user_id

echo ""
print_section_header "✅ REGISTRASI BERHASIL"
print_info "Nama    : ${author}"
print_info "IP      : ${MYIP}"
print_info "Durasi  : ${custom_days} Hari"
print_info "Expired : ${expired_date} (YYYY-MM-DD)"
echo ""
print_warning "Script akan expired pada tanggal di atas"
echo ""
read -p "   Tekan Enter untuk melanjutkan..."
clear
}

# ==================== FUNCTION DOMAIN ====================
function domain(){
res1() {
run_task "Setting up pointing script" "wget -q ${REPO}install/pointing.sh && chmod +x pointing.sh && ./pointing.sh >/dev/null 2>&1"
clear
}

clear
cd
print_section_header "🎯 SETUP DOMAIN VPS"
echo -e "${MODERN_DIM}────────────────────────────────────────────────${RESET_ALL}"
echo -e "  ${MODERN_CYAN}1.${RESET_ALL} ${MODERN_BOLD}Gunakan Domain Sendiri${RESET_ALL}"
echo -e "  ${MODERN_CYAN}2.${RESET_ALL} ${MODERN_BOLD}Gunakan Domain Random${RESET_ALL}"
echo -e "${MODERN_DIM}────────────────────────────────────────────────${RESET_ALL}"

until [[ $domain =~ ^[12]+$ ]]; do
read -p "   Pilih opsi 1 atau 2 : " domain
done

if [[ $domain == "1" ]]; then
clear
print_section_header "🙏 TERIMA KASIH"
print_info "SUDAH MENGGUNAKAN SCRIPT PEYX TUNNELING"
echo ""
until [[ $dnss =~ ^[a-zA-Z0-9_.-]+$ ]]; do
read -rp "🌐 Masukkan domain Anda: " -e dnss
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
echo ""
clear
fi

if [[ $domain == "2" ]]; then
clear
print_section_header "Contoh Domain Random"
print_info "peyx → peyx.peyx.me"
echo ""
until [[ $dn1 =~ ^[a-zA-Z0-9_.-]+$ ]]; do
read -rp "🌐 Masukkan subdomain (tanpa spasi): " -e dn1
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
echo ""
clear
cd
sleep 1
res1
clear
rm /root/subdomainx
fi
}

# ==================== FUNCTION PASANG ====================
# ==================== FUNCTION PASANG (DIPERBAIKI) ====================
function Pasang(){
cd
run_task "Downloading tools" "wget -q ${REPO}tools.sh && chmod +x tools.sh"
run_task "Running tools" "bash tools.sh >/dev/null 2>&1"
clear
start=$(date +%s)
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
run_task "Installing git and curl" "apt install git curl -y >/dev/null 2>&1"

# Install python dengan fallback ke python3
if command -v python3 &>/dev/null; then
    print_success "Python3 already installed"
else
    run_task "Installing python3" "apt install python3 -y >/dev/null 2>&1"
    # Buat symlink python ke python3 jika perlu
    if [ ! -f /usr/bin/python ] && [ -f /usr/bin/python3 ]; then
        ln -s /usr/bin/python3 /usr/bin/python 2>/dev/null
    fi
fi

# Install python-is-python3 untuk Ubuntu/Debian modern
if [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "ubuntu" ]] || \
   [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "debian" ]]; then
    run_task "Installing python-is-python3" "apt install python-is-python3 -y >/dev/null 2>&1"
fi
}

# ==================== FUNCTION INSTALLASI ====================
function Installasi(){
res2() {
run_task "Installing SSH & OpenVPN" "wget -q ${REPO}install/ssh-vpn.sh && chmod +x ssh-vpn.sh && ./ssh-vpn.sh >/dev/null 2>&1"
clear
}
res3() {
run_task "Installing XRAY" "wget -q ${REPO}install/ins-xray.sh && chmod +x ins-xray.sh && ./ins-xray.sh >/dev/null 2>&1"
clear
}
res4() {
run_task "Installing Websocket" "wget -q ${REPO}sshws/insshws.sh && chmod +x insshws.sh && ./insshws.sh >/dev/null 2>&1"
clear
}
res5() {
run_task "Installing Backup System" "wget -q ${REPO}install/set-br.sh && chmod +x set-br.sh && ./set-br.sh >/dev/null 2>&1"
clear
}
res6() {
run_task "Installing OHP" "wget -q ${REPO}sshws/ohp.sh && chmod +x ohp.sh && ./ohp.sh >/dev/null 2>&1"
clear
}
res7() {
run_task "Installing Extra Menu" "wget -q ${REPO}menu/update.sh && chmod +x update.sh && ./update.sh >/dev/null 2>&1"
clear
}
res8() {
run_task "Installing SlowDNS" "wget -q ${REPO}slowdns/installsl.sh && chmod +x installsl.sh && bash installsl.sh >/dev/null 2>&1"
clear
}
res9() {
run_task "Installing UDP Custom" "wget -q ${REPO}install/udp-custom.sh && chmod +x udp-custom.sh && bash udp-custom.sh >/dev/null 2>&1"
clear
}
res10() {
run_task "Installing API Server" "wget -q ${REPO}install/api-px.sh && chmod +x api-px.sh && bash api-px.sh >/dev/null 2>&1"
clear
}
res11() {
run_task "Fix HAPROXY" "wget -q ${REPO}install/fixhap.sh && chmod +x fixhap.sh && bash fixhap.sh >/dev/null 2>&1"
clear
}

if [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "ubuntu" ]]; then
print_info "Setup nginx For OS: $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')"
setup_ubuntu
elif [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "debian" ]]; then
print_info "Setup nginx For OS: $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')"
setup_debian
else
print_error "Your OS Is Not Supported"
fi
}

# ==================== FUNCTION SETUP DEBIAN ====================
function setup_debian(){
print_section_header "INSTALL SSH & OPENVPN"
res2

print_section_header "INSTALL XRAY MOD PX"
res3

print_section_header "INSTALL WEBSOCKET"
res4

print_section_header "BACKUP SYSTEM"
res5

print_section_header "INSTALL OHP"
res6

print_section_header "EXTRA MENU"
res7

print_section_header "SLOWDNS SYSTEM"
res8

print_section_header "UDP CUSTOM"
res9

print_section_header "API SERVER"
res10

print_section_header "FIX HAPROXY"
res11

}

# ==================== FUNCTION SETUP UBUNTU ====================
function setup_ubuntu(){
print_section_header "INSTALL SSH & OPENVPN"
res2

print_section_header "INSTALL XRAY MOD PX"
res3

print_section_header "INSTALL WEBSOCKET"
res4

print_section_header "BACKUP SYSTEM"
res5

print_section_header "INSTALL OHP"
res6

print_section_header "EXTRA MENU"
res7

print_section_header "SLOWDNS SYSTEM"
res8

print_section_header "UDP CUSTOM"
res9

print_section_header "API SERVER"
res10

print_section_header "FIX HAPROXY"
res11

}

# ==================== FUNCTION NOTIF TELEGRAM ====================
function iinfo(){
domain=$(cat /etc/xray/domain)
TIMES="10"
CHATID="7661292905"
KEY="8485191955:AAE3H7QmWVprrGwRpWYIvEZHYf6DArQtWV4"
URL="https://api.telegram.org/bot$KEY/sendMessage"
ISP=$(cat /etc/xray/isp)
CITY=$(cat /etc/xray/city)
TIME=$(date +'%Y-%m-%d %H:%M:%S')
RAMMS=$(free -m | awk 'NR==2 {print $2}')
MODEL2=$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')
MYIP=$(curl -sS ipv4.icanhazip.com)

# Mengambil nilai auth (sesuaikan path file auth anda)
AUTH=$(cat /etc/peyx-api/px-auth 2>/dev/null || echo "Tidak ada auth")

if [[ -f /etc/xray/expired_date ]]; then
    IZIN=$(cat /etc/xray/expired_date)
else
    IZIN=$(curl -sS https://raw.githubusercontent.com/PeyxDev/esce/main/ipx | grep "$MYIP" | head -1 | awk '{print $3}')
fi

if [[ -f /etc/xray/user_id ]]; then
    NAMA_IZIN=$(cat /etc/xray/user_id)
else
    NAMA_IZIN=$(curl -sS https://raw.githubusercontent.com/PeyxDev/esce/main/ipx | grep "$MYIP" | head -1 | awk '{print $2}')
fi

today=$(date +%Y-%m-%d)
d1=$(date -d "$IZIN" +%s 2>/dev/null)
d2=$(date -d "$today" +%s)
EXP=$(( (d1 - d2) / 86400 ))

if [[ $EXP -lt 0 ]]; then
    EXP=0
fi

TEXT="
<code>━━━━━━━━━━━━━━━━━━━━</code>
<code>✅ AUTOSCRIPT PREMIUM </code>
<code>━━━━━━━━━━━━━━━━━━━━</code>
<code>NAMA     : </code><code>${NAMA_IZIN}</code>
<code>TIME     : </code><code>${TIME} WIB</code>
<code>DOMAIN   : </code><code>${domain}</code>
<code>IP       : </code><code>${MYIP}</code>
<code>ISP      : </code><code>${ISP} $CITY</code>
<code>OS       : </code><code>${MODEL2}</code>
<code>RAM      : </code><code>${RAMMS} MB</code>
<code>EXPIRED  : </code><code>$EXP Days ($IZIN)</code>
<code>AUTH     : </code><code>${AUTH}</code>
<code>━━━━━━━━━━━━━━━━━━━━</code>
<i> Notifikasi Installer Script...</i>
"

curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
}

# ==================== EKSEKUSI INSTALLASI ====================
key2
CEKIP
Installasi

# Konfigurasi sysctl
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

# Konfigurasi resolv.conf
sudo systemctl disable systemd-resolved 2>/dev/null
sudo systemctl stop systemd-resolved 2>/dev/null
sudo rm /etc/resolv.config 2>/dev/null
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" | sudo tee /etc/resolv.conf >/dev/null
sudo chattr +i /etc/resolv.conf 2>/dev/null
sudo systemctl start systemd-resolved 2>/dev/null
sudo systemctl enable systemd-resolved 2>/dev/null

# Setup profile
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

# Bersihkan file temporary
rm /root/tools.sh >/dev/null 2>&1
rm /root/setup.sh >/dev/null 2>&1
rm /root/pointing.sh >/dev/null 2>&1
rm /root/ssh-vpn.sh >/dev/null 2>&1
rm /root/ins-xray.sh >/dev/null 2>&1
rm /root/insshws.sh >/dev/null 2>&1
rm /root/set-br.sh >/dev/null 2>&1
rm /root/ohp.sh >/dev/null 2>&1
rm /root/update.sh >/dev/null 2>&1
rm /root/installsl.sh >/dev/null 2>&1
rm /root/udp-custom.sh >/dev/null 2>&1
rm /root/api-px.sh >/dev/null 2>&1

# Simpan info
cd
curl -sS ifconfig.me > /etc/myipvps
curl -s ipinfo.io/city?token=75082b4831f909 >> /etc/xray/city
curl -s ipinfo.io/org?token=75082b4831f909 | cut -d " " -f 2-10 >> /etc/xray/isp

serverV=$(curl -sS ${REPO}versi)
echo $serverV > /opt/.ver

# Tampilkan summary
clear
print_section_header "✅ INSTALLATION COMPLETE"
print_info "Domain      : $(cat /etc/xray/domain)"
print_info "IP Address  : $(curl -s ipv4.icanhazip.com)"
print_info "$(secs_to_human "$(($(date +%s) - ${start}))")"
echo ""

# Kirim notifikasi Telegram
iinfo

# Tanya reboot
echo -e "${YELLOW}  Apakah Anda ingin reboot sekarang? (y/n)${NC}"
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
    exit 0
else
    reboot
fi
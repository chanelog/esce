sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"

function VALIDASI_IP() {
    clear
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│          VALIDASI WHITELIST IP           │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    
    MYIP=$(curl -sS ipv4.icanhazip.com)
    echo -e "IP VPS Anda: ${green}$MYIP${NC}"
    echo ""
    
    # Download whitelist terbaru
    echo -e "${yellow}Mengambil data whitelist...${NC}"
    WHITELIST_URL="https://raw.githubusercontent.com/PeyxDev/esce/main/ipx"
    curl -sS --connect-timeout 10 "$WHITELIST_URL" > /tmp/whitelist_check.txt
    
    if [ $? -ne 0 ]; then
        echo -e "${red}✗ Gagal mengambil data whitelist${NC}"
        echo -e "${yellow}Periksa koneksi internet dan repository${NC}"
        exit 1
    fi
    
    # Cek IP di whitelist
    if grep -q "$MYIP" /tmp/whitelist_check.txt; then
        IP_DATA=$(grep "$MYIP" /tmp/whitelist_check.txt)
        echo -e "${green}✓ IP DITEMUKAN di whitelist${NC}"
        echo -e "Data: $IP_DATA"
        echo ""
        rm -f /tmp/whitelist_check.txt
        return 0
    else
        echo -e "${red}✗ IP TIDAK TERDAFTAR di whitelist${NC}"
        echo ""
        echo -e "${yellow}Solusi:${NC}"
        echo -e "1. Hubungi admin untuk mendaftarkan IP: ${green}$MYIP${NC}"
        echo -e "2. Pastikan IP sudah terdaftar di file ipx repository"
        echo -e "3. Repository: ${green}https://github.com/PeyxDev/esce${NC}"
        echo ""
        rm -f /tmp/whitelist_check.txt
        exit 1
    fi
}

function CEKIP() {
    MYIP=$(curl -sS ipv4.icanhazip.com)
    
    # Validasi ketat - hanya lanjut jika IP terdaftar
    IPVPS=$(curl -sS --connect-timeout 10 "https://raw.githubusercontent.com/PeyxDev/esce/main/ipx" | grep "$MYIP" | awk '{print $4}')
    
    if [[ "$MYIP" == "$IPVPS" ]]; then
        echo -e "${green}✓ Validasi IP berhasil - Lanjut installasi${NC}"
        domain
        Pasang
    else
        echo -e "${red}✗ Validasi IP gagal${NC}"
        echo -e "${yellow}IP $MYIP tidak terdaftar di whitelist${NC}"
        echo -e "${red}Installasi dibatalkan untuk keamanan${NC}"
        exit 1
    fi
}

clear
red='\e[1;31m'
green='\e[0;32m'
yell='\e[1;33m'
tyblue='\e[1;36m'
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

clear
echo -e "[ ${green}INFO${NC} ] Aight good ... installation file is ready"
echo -e "$green                                                                                         $NC"
echo -e "$green____ _  _ ___ ____    _ _  _ ____ ___ ____ _    _   $NC"
echo -e "$green|__| |  |  |  |  |    | |\ | [__   |  |__| |    |   $NC"
echo -e "$green|  | |__|  |  |__|    | | \| ___]  |  |  | |___ |___$NC"
echo -e "$green                                                      $NC"
echo -e "$green                ____ ____ _  _ $NC"
echo -e "$green                [__  [__  |__|$NC"
echo -e "$green                ___] ___] |  |$NC"
echo -e "$green                $NC"
echo -e "$green♥ TERIMAKSIH TELAH MEMAKAI SCRIPT PeyxDev ♥$NC"
sleep 2

echo -e  "${green}┌──────────────────────────────────────────┐${NC}"
echo -e  "${green}│              MASUKKAN NAMA KAMU          │${NC}"
echo -e  "${green}└──────────────────────────────────────────┘${NC}"
echo " "
until [[ $name =~ ^[a-zA-Z0-9_.-]+$ ]]; do
    read -rp "Masukan Nama Kamu Disini tanpa spasi : " -e name
done
echo "PeyxDev" > /etc/xray/username
echo ""
clear
author=$name
echo ""
echo ""

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
        echo -ne "  \033[0;33mUpdate Domain.. \033[1;37m- \033[0;33m["
        while true; do
            for ((i = 0; i < 18; i++)); do
                echo -ne "\033[0;32m#"
                sleep 0.1s
            done
            [[ -e $HOME/fim ]] && rm $HOME/fim && break
            echo -e "\033[0;33m]"
            sleep 1s
            tput cuu1
            tput dl1
            echo -ne "  \033[0;33mUpdate Domain... \033[1;37m- \033[0;33m["
        done
        echo -e "\033[0;33m]\033[1;37m -\033[1;32m Succes !\033[1;37m"
        tput cnorm
    }
    
    res1() {
        wget ${REPO}install/pointing.sh && chmod +x pointing.sh && ./pointing.sh
        clear
    }
    
    clear
    cd
    echo -e "$green━━━━━━━━━━┏┓━━━━━━━━━━━━━━━━━━━━━━━━┏┓━━━━━━━━━━━$NC"
    echo -e "$green━━━━━━━━━┏┛┗┓━━━━━━━━━━━━━━━━━━━━━━┏┛┗┓━━━━━━━━━━$NC"
    echo -e "$green┏━━┓━┏┓┏┓┗┓┏┛┏━━┓━━━━┏━━┓┏━━┓┏┓┏━┓━┗┓┏┛┏┓┏━┓━┏━━┓$NC"
    echo -e "$green┗━┓┃━┃┃┃┃━┃┃━┃┏┓┃━━━━┃┏┓┃┃┏┓┃┣┫┃┏┓┓━┃┃━┣┫┃┏┓┓┃┏┓┃$NC"
    echo -e "$green┃┗┛┗┓┃┗┛┃━┃┗┓┃┗┛┃━━━━┃┗┛┃┃┗┛┃┃┃┃┃┃┃━┃┗┓┃┃┃┃┃┃┃┗┛┃$NC"
    echo -e "$green┗━━━┛┗━━┛━┗━┛┗━━┛━━━━┃┏━┛┗━━┛┗┛┗┛┗┛━┗━┛┗┛┗┛┗┛┗━┓┃$NC"
    echo -e "$green━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━┏━┛┃$NC"
    echo -e "$green━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━┗━━┛$NC"
    echo -e "$BBlue                     SETUP DOMAIN VPS     $NC"
    echo -e "$BYellow----------------------------------------------------------$NC"
    echo -e "$BGreen 1. Use Domain Random / Gunakan Domain Sendiri $NC"
    echo -e "$BGreen 2. Choose Your Own Domain / Gunakan Domain Random $NC"
    echo -e "$BYellow----------------------------------------------------------$NC"
    
    until [[ $domain =~ ^[12]+$ ]]; do
        read -p "   Please select numbers 1 atau 2 : " domain
    done
    
    if [[ $domain == "1" ]]; then
        clear
        echo -e  "${green}┌──────────────────────────────────────────┐${NC}"
        echo -e  "${green}│              \033[1;37mTERIMA KASIH                ${green}│${NC}"
        echo -e  "${green}│         \033[1;37mSUDAH MENGGUNAKAN SCRIPT         ${green}│${NC}"
        echo -e  "${green}│                \033[1;37mPEYX TUNNELING            ${green}│${NC}"
        echo -e  "${green}└──────────────────────────────────────────┘${NC}"
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
        echo ""
        clear
    fi
    
    if [[ $domain == "2" ]]; then
        clear
        echo -e  "${green}┌──────────────────────────────────────────┐${NC}"
        echo -e  "${green}│  \033[1;37mContoh subdomain ( peyx )                       ${green}│${NC}"
        echo -e  "${green}│    \033[1;37mxxx.peyx.me jadi subdomain kamu               ${green}│${NC}"
        echo -e  "${green}└──────────────────────────────────────────┘${NC}"
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
        echo ""
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
    # SKIP TOOLS.SH - Langsung mulai installasi
    clear
    start=$(date +%s)
    ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
    
    # Update repository dan install dependencies dasar
    apt update -y >/dev/null 2>&1
    apt install curl git python3 -y >/dev/null 2>&1
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
        echo -ne "  \033[0;33mLagi Menginstal File \033[1;37m- \033[0;33m["
        while true; do
            for ((i = 0; i < 18; i++)); do
                echo -ne "\033[0;32m#"
                sleep 0.1
            done
            if [[ -e $HOME/fim ]]; then
                rm -f $HOME/fim
                break
            fi
            echo -e "\033[0;33m]"
            sleep 1
            tput cuu1
            tput dl1
            echo -ne "  \033[0;33mLagi Menginstal File \033[1;37m- \033[0;33m["
        done
        echo -e "\033[0;33m]\033[1;37m -\033[1;32m Succes !\033[1;37m"
        tput cnorm
    }
    
    res2() {
        # Fix untuk netfilter-persistent
        wget ${REPO}install/ssh-vpn.sh -O /tmp/ssh-vpn.sh
        # Patch script untuk menghindari netfilter-persistent
        sed -i 's/apt install -y netfilter-persistent/# apt install -y netfilter-persistent/g' /tmp/ssh-vpn.sh
        sed -i 's/systemctl enable netfilter-persistent/# systemctl enable netfilter-persistent/g' /tmp/ssh-vpn.sh
        chmod +x /tmp/ssh-vpn.sh && /tmp/ssh-vpn.sh
        clear
    }
    
    res3() {
        wget ${REPO}install/ins-xray.sh && chmod +x ins-xray.sh && ./ins-xray.sh
        clear
    }
    
    res4() {
        wget ${REPO}sshws/insshws.sh && chmod +x insshws.sh && ./insshws.sh
        clear
    }
    
    res5() {
        wget ${REPO}install/set-br.sh && chmod +x set-br.sh && ./set-br.sh
        clear
    }
    
    res6() {
        wget ${REPO}sshws/ohp.sh && chmod +x ohp.sh && ./ohp.sh
        clear
    }
    
    res7() {
        wget ${REPO}menu/update.sh && chmod +x update.sh && ./update.sh
        clear
    }
    
    res8() {
        wget ${REPO}slowdns/installsl.sh && chmod +x installsl.sh && bash installsl.sh
        clear
    }
    
    res9() {
        wget ${REPO}install/udp-custom.sh && chmod +x udp-custom.sh && bash udp-custom.sh
        clear
    }
    
    if [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "ubuntu" ]]; then
        echo -e "${green}Setup untuk OS: $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${NC}"
        setup_ubuntu
    elif [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "debian" ]]; then
        echo -e "${green}Setup untuk OS: $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${NC}"
        setup_debian
    else
        echo -e "${yellow}OS: $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${NC}"
        setup_generic
    fi
}

function setup_debian(){
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│      PROCESS INSTALLED SSH & OPENVPN     │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res2'
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           PROCESS INSTALLED XRAY         │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res3'
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│       PROCESS INSTALLED WEBSOCKET SSH    │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res4'
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│       PROCESS INSTALLED BACKUP MENU      │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res5'
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           PROCESS INSTALLED OHP          │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res6'
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           DOWNLOAD EXTRA MENU            │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res7'
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           DOWNLOAD SYSTEM                │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res8'
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           DOWNLOAD UDP COSTUM            │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    fun_bar 'res9'
}

function setup_ubuntu(){
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│      PROCESS INSTALLED SSH & OPENVPN     │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res2
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           PROCESS INSTALLED XRAY         │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res3
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│       PROCESS INSTALLED WEBSOCKET SSH    │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res4
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│       PROCESS INSTALLED BACKUP MENU      │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res5
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           PROCESS INSTALLED OHP          │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res6
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           DOWNLOAD EXTRA MENU            │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res7
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           DOWNLOAD SYSTEM                │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res8
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           DOWNLOAD UDP COSTUM            │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res9
}

function setup_generic(){
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│      PROCESS INSTALLED SSH & OPENVPN     │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res2
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           PROCESS INSTALLED XRAY         │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res3
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│       PROCESS INSTALLED WEBSOCKET SSH    │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res4
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│       PROCESS INSTALLED BACKUP MENU      │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res5
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           PROCESS INSTALLED OHP          │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res6
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           DOWNLOAD EXTRA MENU            │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res7
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           DOWNLOAD SYSTEM                │${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    res8
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│           DOWNLOAD UDP COSTUM            │${NC}"
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
<code>⚠️ AUTOSCRIPT PREMIUM ⚠️</code>
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

# ========== MAIN EXECUTION ==========

# Validasi IP manual terlebih dahulu
VALIDASI_IP

# Setup sysctl
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

# Mulai installasi
CEKIP
Installasi

# Setup DNS
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo rm -f /etc/resolv.conf
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" | sudo tee /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
sudo systemctl start systemd-resolved
sudo systemctl enable systemd-resolved

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

# Cleanup
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

# Cleanup script files
rm -f /root/tools.sh >/dev/null 2>&1
rm -f /root/setup.sh >/dev/null 2>&1
rm -f /root/pointing.sh >/dev/null 2>&1
rm -f /root/ssh-vpn.sh >/dev/null 2>&1
rm -f /root/ins-xray.sh >/dev/null 2>&1
rm -f /root/insshws.sh >/dev/null 2>&1
rm -f /root/set-br.sh >/dev/null 2>&1
rm -f /root/ohp.sh >/dev/null 2>&1
rm -f /root/update.sh >/dev/null 2>&1
rm -f /root/installsl.sh >/dev/null 2>&1
rm -f /root/udp-custom.sh >/dev/null 2>&1

# Final
secs_to_human "$(($(date +%s) - ${start}))" | tee -a log-install.txt
sleep 3
echo ""
cd
iinfo

echo -e "${green}┌────────────────────────────────────────────┐${NC}"
echo -e "${green}│  INSTALL SCRIPT SELESAI..                  │${NC}"
echo -e "${green}└────────────────────────────────────────────┘${NC}"
echo ""
sleep 4
echo -e "[ ${yell}WARNING${NC} ] Do you want to reboot now ? (y/n)? "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
    exit 0
else
    reboot
fi

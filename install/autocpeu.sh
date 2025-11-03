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
    echo -e "${yellow}           SCRIPT LICENSE CHECK${neutral}"
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
            echo -e " Script version is up to date ($serverV) ${green}✓${neutral}"
            return
        else
            echo -e " New version available, updating script..."
            run_with_spinner "Downloading update script..." wget -q https://raw.githubusercontent.com/PeyxDev/esce/main/menu/update.sh -O update.sh
            run_with_spinner "Setting execute permissions..." chmod +x update.sh
            run_with_spinner "Running update process..." ./update.sh
            run_with_spinner "Updating version record..." echo $serverV > /opt/.ver.local
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
        echo -e "      ${green}WhatsApp${neutral} wa.me/62831516636921"
        echo -e "      ${green}Telegram${neutral} t.me/frel01"
        echo -e "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
        
        cd
        run_with_spinner "Cleaning cron jobs..." bash -c '> /etc/cron.d/cpu_otm'
        
        run_with_spinner "Setting up monitoring cron..." bash -c 'cat> /etc/cron.d/cpu_otm << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * root /usr/bin/detek
END'
        
        run_with_spinner "Downloading detection script..." wget -q https://raw.githubusercontent.com/PeyxDev/esce/main/install/detek
        run_with_spinner "Installing detection binary..." mv detek /usr/bin/detek
        run_with_spinner "Setting execution permissions..." chmod +x /usr/bin/detek
        run_with_spinner "Running system detection..." detek
        
        echo -e "${yellow}Loading Extract and Setup detek${neutral}"
    fi
}

clear
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${yellow}           LICENSE VALIDATION SYSTEM${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"

# Run version check
check_script_version

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔒 LICENSE CHECK COMPLETED ${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${yellow}Script validation process finished${neutral}"
echo ""
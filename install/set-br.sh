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

clear
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${yellow}           BACKUP & BANDWIDTH MANAGEMENT${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"

REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}☁️  INSTALLING RCLONE BACKUP TOOL${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Installing rclone..." apt install rclone -y
run_with_spinner "Initializing rclone configuration..." printf "q\n" | rclone config
run_with_spinner "Downloading rclone configuration..." wget -O /root/.config/rclone/rclone.conf "${REPO}install/rclone.conf"

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}📊 INSTALLING WONDERSHAPER BANDWIDTH MANAGER${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Cloning wondershaper repository..." git clone https://github.com/casper9/wondershaper.git
run_with_spinner "Installing wondershaper..." cd wondershaper && make install
run_with_spinner "Cleaning up wondershaper source..." cd && rm -rf wondershaper

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔧 APPLYING BANDWIDTH LIMITS${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Downloading bandwidth limit script..." wget -q ${REPO}install/limit.sh
run_with_spinner "Setting script permissions..." chmod +x limit.sh
run_with_spinner "Applying bandwidth limits..." ./limit.sh

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🧹 CLEANING UP INSTALLATION FILES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Removing temporary files..." rm -f /root/set-br.sh /root/limit.sh

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🎉 BACKUP & BANDWIDTH SETUP COMPLETED${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${yellow}Services and tools installed:${neutral}"
echo -e "${blue}• RClone Backup Tool${neutral}"
echo -e "${blue}• Wondershaper Bandwidth Manager${neutral}"
echo -e "${blue}• Bandwidth Limit Configuration${neutral}"
echo -e "${green}All backup and bandwidth management tools are ready!${neutral}"
echo ""
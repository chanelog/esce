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
echo -e "${yellow}           IP LIMIT SERVICE INSTALLATION${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"

REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}📥 DOWNLOADING IP LIMIT SCRIPTS${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Downloading limit-ip script..." wget -q -O /usr/bin/limit-ip "${REPO}install/limit-ip"
run_with_spinner "Setting script permissions..." chmod +x /usr/bin/*
run_with_spinner "Fixing line endings..." cd /usr/bin && sed -i 's/\r//' limit-ip && cd
run_with_spinner "Reloading system daemon..." systemctl daemon-reload

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}⚙️  INSTALLING SERVICE FILES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Installing VMess limit service..." wget -q -O /etc/systemd/system/limitvmess.service "${REPO}install/limitvmess.service"
run_with_spinner "Installing VLess limit service..." wget -q -O /etc/systemd/system/limitvless.service "${REPO}install/limitvless.service"
run_with_spinner "Installing Trojan limit service..." wget -q -O /etc/systemd/system/limittrojan.service "${REPO}install/limittrojan.service"
run_with_spinner "Installing Shadowsocks limit service..." wget -q -O /etc/systemd/system/limitshadowsocks.service "${REPO}install/limitshadowsocks.service"

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}📊 DOWNLOADING LIMIT CONFIGURATIONS${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Downloading VMess limit config..." wget -q -O /etc/xray/limit.vmess "${REPO}install/vmess"
run_with_spinner "Downloading VLess limit config..." wget -q -O /etc/xray/limit.vless "${REPO}install/vless"
run_with_spinner "Downloading Trojan limit config..." wget -q -O /etc/xray/limit.trojan "${REPO}install/trojan"
run_with_spinner "Downloading Shadowsocks limit config..." wget -q -O /etc/xray/limit.shadowsocks "${REPO}install/shadowsocks"

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔧 SETTING PERMISSIONS${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Setting VMess config permissions..." chmod +x /etc/xray/limit.vmess
run_with_spinner "Setting VLess config permissions..." chmod +x /etc/xray/limit.vless
run_with_spinner "Setting Trojan config permissions..." chmod +x /etc/xray/limit.trojan
run_with_spinner "Setting Shadowsocks config permissions..." chmod +x /etc/xray/limit.shadowsocks

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🚀 ACTIVATING SERVICES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Reloading system daemon..." systemctl daemon-reload
run_with_spinner "Enabling VMess limit service..." systemctl enable --now limitvmess
run_with_spinner "Enabling VLess limit service..." systemctl enable --now limitvless
run_with_spinner "Enabling Trojan limit service..." systemctl enable --now limittrojan
run_with_spinner "Enabling Shadowsocks limit service..." systemctl enable --now limitshadowsocks
run_with_spinner "Starting VMess limit service..." systemctl start limitvmess
run_with_spinner "Starting VLess limit service..." systemctl start limitvless
run_with_spinner "Starting Trojan limit service..." systemctl start limittrojan
run_with_spinner "Starting Shadowsocks limit service..." systemctl start limitshadowsocks

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🎉 IP LIMIT SERVICES INSTALLED${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${yellow}Services installed and activated:${neutral}"
echo -e "${blue}• VMess IP Limit${neutral}"
echo -e "${blue}• VLess IP Limit${neutral}"
echo -e "${blue}• Trojan IP Limit${neutral}"
echo -e "${blue}• Shadowsocks IP Limit${neutral}"
echo -e "${green}All IP limit services are now running!${neutral}"
echo ""
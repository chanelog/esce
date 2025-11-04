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

echo -e "${blue}Starting IP Limit Installation...${neutral}"
echo -e "${purple}=========================================${neutral}"

REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"

run_with_spinner "Downloading limit-ip script..." wget -q -O /usr/bin/limit-ip "${REPO}install/limit-ip"

run_with_spinner "Setting permissions..." chmod +x /usr/bin/*

run_with_spinner "Fixing line endings..." cd /usr/bin
sed -i 's/\r//' limit-ip
cd

run_with_spinner "Reloading systemd..." systemctl daemon-reload

run_with_spinner "Downloading Vmess limit service..." wget -q -O /etc/systemd/system/limitvmess.service "${REPO}install/limitvmess.service" && chmod +x /etc/systemd/system/limitvmess.service >/dev/null 2>&1

run_with_spinner "Downloading Vless limit service..." wget -q -O /etc/systemd/system/limitvless.service "${REPO}install/limitvless.service" && chmod +x /etc/systemd/system/limitvless.service >/dev/null 2>&1

run_with_spinner "Downloading Trojan limit service..." wget -q -O /etc/systemd/system/limittrojan.service "${REPO}install/limittrojan.service" && chmod +x /etc/systemd/system/limittrojan.service >/dev/null 2>&1

run_with_spinner "Downloading Shadowsocks limit service..." wget -q -O /etc/systemd/system/limitshadowsocks.service "${REPO}install/limitshadowsocks.service" && chmod +x /etc/systemd/system/limitshadowsocks.service >/dev/null 2>&1

run_with_spinner "Downloading Vmess limit config..." wget -q -O /etc/xray/limit.vmess "${REPO}install/vmess" >/dev/null 2>&1

run_with_spinner "Downloading Vless limit config..." wget -q -O /etc/xray/limit.vless "${REPO}install/vless" >/dev/null 2>&1

run_with_spinner "Downloading Trojan limit config..." wget -q -O /etc/xray/limit.trojan "${REPO}install/trojan" >/dev/null 2>&1

run_with_spinner "Downloading Shadowsocks limit config..." wget -q -O /etc/xray/limit.shadowsocks "${REPO}install/shadowsocks" >/dev/null 2>&1

run_with_spinner "Setting config permissions..." chmod +x /etc/xray/limit.vmess
chmod +x /etc/xray/limit.vless
chmod +x /etc/xray/limit.trojan
chmod +x /etc/xray/limit.shadowsocks

run_with_spinner "Reloading systemd daemon..." systemctl daemon-reload

run_with_spinner "Enabling Vmess limit service..." systemctl enable --now limitvmess

run_with_spinner "Enabling Vless limit service..." systemctl enable --now limitvless

run_with_spinner "Enabling Trojan limit service..." systemctl enable --now limittrojan

run_with_spinner "Enabling Shadowsocks limit service..." systemctl enable --now limitshadowsocks

run_with_spinner "Starting Vmess limit service..." systemctl start limitvmess

run_with_spinner "Starting Vless limit service..." systemctl start limitvless

run_with_spinner "Starting Trojan limit service..." systemctl start limittrojan

run_with_spinner "Starting Shadowsocks limit service..." systemctl start limitshadowsocks

echo -e "${purple}=========================================${neutral}"
echo -e "${green}IP Limit Installation Completed Successfully!${neutral}"
echo -e "${blue}Services installed and started:${neutral}"
echo -e "${yellow}• Vmess IP Limit${neutral}"
echo -e "${yellow}• Vless IP Limit${neutral}"
echo -e "${yellow}• Trojan IP Limit${neutral}"
echo -e "${yellow}• Shadowsocks IP Limit${neutral}"
echo -e "${purple}=========================================${neutral}"
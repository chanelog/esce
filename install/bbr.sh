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

function Add_To_New_Line(){
    if [ "$(tail -n1 $1 | wc -l)" == "0"  ];then
        echo "" >> "$1"
    fi
    echo "$2" >> "$1"
}

function Check_And_Add_Line(){
    if [ -z "$(cat "$1" | grep "$2")" ];then
        Add_To_New_Line "$1" "$2"
    fi
}

function Install_BBR(){
    echo -e "${blue} ────────────────────────────────────────────────${neutral}"
    echo -e "${yellow}           INSTALLING TCP BBR${neutral}"
    echo -e "${blue} ────────────────────────────────────────────────${neutral}"
    
    if [ -n "$(lsmod | grep bbr)" ];then
        echo -e " TCP BBR already installed ${green}✓${neutral}"
        return 1
    fi
    
    run_with_spinner "Loading TCP BBR module..." modprobe tcp_bbr
    run_with_spinner "Adding BBR to modules..." Add_To_New_Line "/etc/modules-load.d/modules.conf" "tcp_bbr"
    run_with_spinner "Configuring qdisc..." Add_To_New_Line "/etc/sysctl.conf" "net.core.default_qdisc = fq"
    run_with_spinner "Setting congestion control..." Add_To_New_Line "/etc/sysctl.conf" "net.ipv4.tcp_congestion_control = bbr"
    run_with_spinner "Applying sysctl settings..." sysctl -p
    
    if [ -n "$(sysctl net.ipv4.tcp_available_congestion_control | grep bbr)" ] && [ -n "$(sysctl net.ipv4.tcp_congestion_control | grep bbr)" ] && [ -n "$(lsmod | grep "tcp_bbr")" ];then
        echo -e " TCP BBR installed successfully ${green}✓${neutral}"
    else
        echo -e " Failed to install TCP BBR ${red}✗${neutral}"
    fi
}

function Optimize_Parameters(){
    echo -e "${blue} ────────────────────────────────────────────────${neutral}"
    echo -e "${yellow}           OPTIMIZING SYSTEM PARAMETERS${neutral}"
    echo -e "${blue} ────────────────────────────────────────────────${neutral}"
    
    run_with_spinner "Setting file limits..." Check_And_Add_Line "/etc/security/limits.conf" "* soft nofile 51200"
    run_with_spinner "Setting hard file limits..." Check_And_Add_Line "/etc/security/limits.conf" "* hard nofile 51200"
    run_with_spinner "Setting root file limits..." Check_And_Add_Line "/etc/security/limits.conf" "root soft nofile 51200"
    run_with_spinner "Setting root hard limits..." Check_And_Add_Line "/etc/security/limits.conf" "root hard nofile 51200"
    
    run_with_spinner "Configuring file system limits..." Check_And_Add_Line "/etc/sysctl.conf" "fs.file-max = 51200"
    run_with_spinner "Setting receive memory..." Check_And_Add_Line "/etc/sysctl.conf" "net.core.rmem_max = 67108864"
    run_with_spinner "Setting send memory..." Check_And_Add_Line "/etc/sysctl.conf" "net.core.wmem_max = 67108864"
    run_with_spinner "Configuring network backlog..." Check_And_Add_Line "/etc/sysctl.conf" "net.core.netdev_max_backlog = 250000"
    run_with_spinner "Setting socket connections..." Check_And_Add_Line "/etc/sysctl.conf" "net.core.somaxconn = 4096"
    
    run_with_spinner "Enabling TCP syncookies..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_syncookies = 1"
    run_with_spinner "Enabling TCP reuse..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_tw_reuse = 1"
    run_with_spinner "Setting TCP finish timeout..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_fin_timeout = 30"
    run_with_spinner "Setting TCP keepalive..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_keepalive_time = 1200"
    run_with_spinner "Configuring local port range..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.ip_local_port_range = 10000 65000"
    
    run_with_spinner "Setting TCP syn backlog..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_max_syn_backlog = 8192"
    run_with_spinner "Setting TCP timewait buckets..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_max_tw_buckets = 5000"
    run_with_spinner "Enabling TCP fastopen..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_fastopen = 3"
    run_with_spinner "Configuring TCP memory..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_mem = 25600 51200 102400"
    run_with_spinner "Setting TCP receive memory..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_rmem = 4096 87380 67108864"
    run_with_spinner "Setting TCP send memory..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_wmem = 4096 65536 67108864"
    run_with_spinner "Enabling TCP MTU probing..." Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_mtu_probing = 1"
    
    run_with_spinner "Applying all optimizations..." sysctl -p > /dev/null 2>&1
    
    echo -e " System parameters optimized ${green}✓${neutral}"
}

clear
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${yellow}           SYSTEM PERFORMANCE OPTIMIZATION${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${gray}Optimasi Speed By PX VPN${neutral}"
echo ""

# Run BBR installation
Install_BBR

# Run system optimization
Optimize_Parameters

# Clean up
run_with_spinner "Cleaning up installation files..." rm -f /root/bbr.sh

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🎉 SYSTEM OPTIMIZATION COMPLETED ${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${yellow}TCP BBR and system parameters have been optimized${neutral}"
echo -e "${blue}System performance has been enhanced!${neutral}"
echo ""
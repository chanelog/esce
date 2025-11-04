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

# File log SSH
LOG_FILE="/tmp/login.db"

echo -e "${blue}Starting SSH Bandwidth Monitor...${neutral}"
echo -e "${purple}=========================================${neutral}"

# Mengambil IP dan pengguna dari log
declare -A user_ips

run_with_spinner "Reading SSH log file..." while IFS= read -r line; do
    # Contoh baris: 2347373 - 'Taryadi' - 127.0.0.1:34834
    user=$(echo "$line" | awk -F"'" '{print $2}')
    ip=$(echo "$line" | awk -F" - " '{print $3}' | cut -d':' -f1)
    port=$(echo "$line" | awk -F":" '{print $NF}')
    
    user_ips["$user"]="$ip:$port"
done < "$LOG_FILE"

echo -e "${green}Found ${#user_ips[@]} active users${neutral}"
echo -e "${purple}=========================================${neutral}"

# Monitor penggunaan bandwidth
while true; do
    echo -e "${blue}Checking bandwidth usage...${neutral}"
    
    for user in "${!user_ips[@]}"; do
        ip_port="${user_ips[$user]}"
        ip=$(echo "$ip_port" | cut -d':' -f1)
        port=$(echo "$ip_port" | cut -d':' -f2)

        # Menggunakan 'ss' untuk mendapatkan statistik koneksi
        traffic_info=$(ss -i state established "( dport = :$port ) or ( sport = :$port )")
        
        # Ambil data bytes_sent dan bytes_received dari output
        bytes_sent=$(echo "$traffic_info" | grep -oP 'bytes_sent:\K\d+')
        bytes_received=$(echo "$traffic_info" | grep -oP 'bytes_received:\K\d+')

        # Tampilkan hasil dengan warna
        if [[ -n "$bytes_sent" ]] || [[ -n "$bytes_received" ]]; then
            echo -e "User: ${yellow}$user${neutral}, IP: ${blue}$ip_port${neutral}, ${green}Bytes Sent: ${bytes_sent:-0}${neutral}, ${orange}Bytes Received: ${bytes_received:-0}${neutral}"
        else
            echo -e "User: ${yellow}$user${neutral}, IP: ${blue}$ip_port${neutral}, ${red}No Data Transferred${neutral}"
        fi
    done
    
    echo -e "${purple}-----------------------------------------${neutral}"
    echo -e "${gray}Next update in 10 seconds...${neutral}"
    sleep 10  # Tunggu 10 detik sebelum memeriksa lagi
done
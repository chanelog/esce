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

function format_bytes() {
    local bytes=$1
    if [[ $bytes -ge 1073741824 ]]; then
        echo "$(echo "scale=2; $bytes/1073741824" | bc) GB"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$(echo "scale=2; $bytes/1048576" | bc) MB"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$(echo "scale=2; $bytes/1024" | bc) KB"
    else
        echo "${bytes} B"
    fi
}

function display_header() {
    clear
    echo -e "${blue} ────────────────────────────────────────────────${neutral}"
    echo -e "${yellow}           SSH CONNECTION MONITOR${neutral}"
    echo -e "${blue} ────────────────────────────────────────────────${neutral}"
    echo ""
}

function initialize_monitoring() {
    local LOG_FILE="/tmp/login.db"
    
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
    echo -e "${bold_white}📊 INITIALIZING SSH MONITORING${neutral}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
    
    # Check if log file exists
    if [[ ! -f "$LOG_FILE" ]]; then
        echo -e "${red}Log file not found: $LOG_FILE${neutral}"
        echo -e "${yellow}Creating empty log file...${neutral}"
        touch "$LOG_FILE"
    fi
    
    run_with_spinner "Loading SSH connection data..." sleep 2
    
    # Mengambil IP dan pengguna dari log
    declare -A user_ips
    
    while IFS= read -r line; do
        # Contoh baris: 2347373 - 'Taryadi' - 127.0.0.1:34834
        user=$(echo "$line" | awk -F"'" '{print $2}')
        ip=$(echo "$line" | awk -F" - " '{print $3}' | cut -d':' -f1)
        port=$(echo "$line" | awk -F":" '{print $NF}')
        
        if [[ -n "$user" && -n "$ip" ]]; then
            user_ips["$user"]="$ip:$port"
        fi
    done < "$LOG_FILE"
    
    echo -e "${green}Found ${#user_ips[@]} active SSH connections${neutral}"
    echo ""
    
    # Monitor penggunaan bandwidth
    local iteration=0
    while true; do
        display_header
        echo -e "${purple}🔄 Monitoring Cycle: $((++iteration))${neutral}"
        echo -e "${gray}Last update: $(date)${neutral}"
        echo ""
        
        local active_connections=0
        
        for user in "${!user_ips[@]}"; do
            ip_port="${user_ips[$user]}"
            ip=$(echo "$ip_port" | cut -d':' -f1)
            port=$(echo "$ip_port" | cut -d':' -f2)

            # Menggunakan 'ss' untuk mendapatkan statistik koneksi
            traffic_info=$(ss -i state established "( dport = :$port )" 2>/dev/null)
            
            # Ambil data bytes_sent dan bytes_received dari output
            bytes_sent=$(echo "$traffic_info" | grep -oP 'bytes_sent:\K\d+' | head -1)
            bytes_received=$(echo "$traffic_info" | grep -oP 'bytes_received:\K\d+' | head -1)

            # Tampilkan hasil dengan format yang rapi
            if [[ -n "$bytes_sent" ]] || [[ -n "$bytes_received" ]]; then
                sent_formatted=$(format_bytes "${bytes_sent:-0}")
                received_formatted=$(format_bytes "${bytes_received:-0}")
                
                printf "${blue}│${neutral} %-15s ${gray}│${neutral} %-20s ${gray}│${neutral} %-12s ${gray}│${neutral} %-12s ${blue}│${neutral}\n" \
                       "👤 $user" "🌐 $ip_port" "⬆️ $sent_formatted" "⬇️ $received_formatted"
                ((active_connections++))
            else
                printf "${blue}│${neutral} %-15s ${gray}│${neutral} %-20s ${gray}│${neutral} %-12s ${gray}│${neutral} %-12s ${blue}│${neutral}\n" \
                       "👤 $user" "🌐 $ip_port" "⬆️ 0 B" "⬇️ 0 B"
            fi
        done
        
        if [[ $active_connections -eq 0 ]]; then
            echo -e "${yellow}No active data transfers detected${neutral}"
        else
            echo -e "${green}Active connections with data transfer: $active_connections${neutral}"
        fi
        
        echo ""
        echo -e "${gray}Press Ctrl+C to stop monitoring${neutral}"
        echo -e "${gray}Refreshing in 10 seconds...${neutral}"
        
        sleep 10  # Tunggu 10 detik sebelum memeriksa lagi
    done
}

# Main execution
display_header
initialize_monitoring

# Cleanup on exit
trtrap '
    echo -e "\n${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
    echo -e "${bold_white}🛑 MONITORING STOPPED${neutral}"
    echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
    echo -e "${yellow}SSH connection monitoring has been terminated${neutral}"
    echo ""
' EXIT
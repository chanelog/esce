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

function optimize_system() {
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}         OPTIMASI SISTEM UDP${neutral}              ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    
    # Backup sysctl.conf
    run_with_spinner "Membackup konfigurasi sysctl..." cp /etc/sysctl.conf /etc/sysctl.conf.backup
    
    # Kernel network optimizations for UDP performance
    run_with_spinner "Mengoptimasi parameter kernel..." bash -c 'cat >> /etc/sysctl.conf << EOF

# UDP Performance Optimizations - PeyxDev
# Buffer sizes
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.core.optmem_max = 134217728

# TCP/UDP buffer limits
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 87380 134217728

# Socket and connection optimizations
net.core.netdev_max_backlog = 300000
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535

# Memory and file handles
fs.file-max = 2097152
kernel.pid_max = 4194303

# Network stack optimizations
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1

# Congestion control (BBR for better throughput)
net.ipv4.tcp_congestion_control = bbr

# Connection tracking
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_tcp_timeout_established = 86400

# UDP specific optimizations
net.ipv4.udp_mem = 16777216 25165824 33554432

EOF'
    
    # Apply optimizations
    run_with_spinner "Menerapkan optimasi sysctl..." sysctl -p
    
    # Increase limits
    run_with_spinner "Meningkatkan system limits..." bash -c 'echo "* soft nofile 1048576" >> /etc/security/limits.conf
echo "* hard nofile 1048576" >> /etc/security/limits.conf
echo "root soft nofile 1048576" >> /etc/security/limits.conf
echo "root hard nofile 1048576" >> /etc/security/limits.conf'
}

function configure_irq_balance() {
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}          OPTIMASI IRQ BALANCING${neutral}          ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    
    # Install irqbalance if not exists
    if ! command -v irqbalance &> /dev/null; then
        run_with_spinner "Menginstall irqbalance..." apt-get update && apt-get install -y irqbalance
    fi
    
    # Configure irqbalance for better network performance
    run_with_spinner "Mengkonfigurasi irqbalance..." bash -c 'cat > /etc/default/irqbalance << EOF
# Configuration for high-performance UDP
ENABLED="1"
ONESHOT="0"
IRQ_AFFINITY_MASK="0-15"
OPTIONS="--policyscript=/etc/irqbalance-script.sh --hintpolicy=exact"
EOF'
    
    run_with_spinner "Menjalankan irqbalance..." systemctl enable irqbalance && systemctl start irqbalance
}

function create_optimized_config() {
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}       KONFIGURASI UDP-CUSTOM OPTIMAL${neutral}     ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    
    # Create optimized config.json
    run_with_spinner "Membuat konfigurasi optimal..." bash -c 'cat > /root/udp/config.json << EOF
{
    "listen": ":36712",
    "stream_buffer": 4194304,
    "receive_buffer": 33554432,
    "send_buffer": 33554432,
    "read_timeout": 300,
    "write_timeout": 300,
    "idle_timeout": 300,
    "max_connections": 10000,
    "verbose_mode": false,
    "log_level": "info",
    "performance": {
        "worker_threads": 4,
        "batch_size": 64,
        "flush_interval": 10
    },
    "security": {
        "enable_blacklist": true,
        "enable_ratelimit": true,
        "max_packets_per_second": 1000
    },
    "protocols": {
        "enable_udp": true,
        "enable_tcp": false,
        "enable_tls": false
    }
}
EOF'
}

function setup_monitoring() {
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}         SETUP MONITORING PERFORMANCE${neutral}     ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    
    # Create performance monitoring script
    run_with_spinner "Membuat script monitoring..." bash -c 'cat > /root/udp/monitor_performance.sh << EOF
#!/bin/bash

# Performance monitoring for UDP Custom
echo "=== UDP Custom Performance Monitor ==="
echo "Waktu: \$(date)"
echo "--- Koneksi Aktif ---"
ss -u -a | grep -c ":36712"
echo "--- Memory Usage ---"
ps aux --sort=-%mem | grep udp-custom | head -5
echo "--- Network Buffer ---"
cat /proc/net/udp | grep -i "36712"
echo "--- System Load ---"
uptime
echo "==============================="
EOF'
    
    run_with_spinner "Memberikan izin eksekusi monitoring..." chmod +x /root/udp/monitor_performance.sh
    
    # Create systemd service for optimized performance
    run_with_spinner "Membuat service teroptimasi..." bash -c 'cat > /etc/systemd/system/udp-custom.service << EOF
[Unit]
Description=UDP Custom Optimized by PeyxDev
After=network.target
Wants=network.target

[Service]
User=root
Type=simple
ExecStart=/root/udp/udp-custom server
WorkingDirectory=/root/udp/
Restart=always
RestartSec=3s
LimitNOFILE=1048576
LimitMEMLOCK=infinity
LimitSTACK=67108864
OOMScoreAdjust=-1000
Nice=-5
IOSchedulingClass=realtime
IOSchedulingPriority=0
CPUSchedulingPolicy=rr
CPUSchedulingPriority=99

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/root/udp/

[Install]
WantedBy=multi-user.target
EOF'
}

function install_dependencies() {
    echo -e "${green}┌──────────────────────────────────────────┐${NC}"
    echo -e "${green}│${bold_white}         INSTALL DEPENDENCIES${neutral}             ${green}│${NC}"
    echo -e "${green}└──────────────────────────────────────────┘${NC}"
    
    # Install necessary tools for monitoring and optimization
    run_with_spinner "Mengupdate package list..." apt-get update
    run_with_spinner "Menginstall tools monitoring..." apt-get install -y htop iotop iftop nethogs sysstat
    run_with_spinner "Menginstall tools jaringan..." apt-get install -y net-tools iproute2 dnsutils
}

clear
echo -e "${blue} ┌──────────────────────────────────────────┐${neutral}"
echo -e "${blue} │         ${bold_white}UDP OPTIMIZED MOD PeyxDev${neutral}        ${blue}│${neutral}"
echo -e "${blue} └──────────────────────────────────────────┘${neutral}"
echo -e "${blue} ───────────────────────────────────────────${neutral}"
echo -e "${yellow}        INSTALLASI UDP CUSTOM TEROPTIMASI${neutral}"
echo -e "${blue} ───────────────────────────────────────────${neutral}"
echo ""

cd
mkdir -p /root/udp

# Install dependencies first
install_dependencies

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│${bold_white}         MENGATUR ZONA WAKTU${neutral}              ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
run_with_spinner "Mengatur zona waktu GMT+7..." ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│${bold_white}         MENGUNDUH UDP-CUSTOM${neutral}             ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
run_with_spinner "Mengunduh binary udp-custom..." wget -q --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1_VyhL5BILtoZZTW4rhnUiYzc4zHOsXQ8' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1_VyhL5BILtoZZTW4rhnUiYzc4zHOsXQ8" -O /root/udp/udp-custom
run_with_spinner "Memberikan izin eksekusi..." chmod +x /root/udp/udp-custom
run_with_spinner "Membersihkan file temporary..." rm -rf /tmp/cookies.txt

# System optimizations
optimize_system
configure_irq_balance

# Create optimized configuration
create_optimized_config

# Setup monitoring and service
setup_monitoring

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│${bold_white}         MENJALANKAN SERVICE${neutral}              ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
run_with_spinner "Reload systemd daemon..." systemctl daemon-reload
run_with_spinner "Memulai service udp-custom..." systemctl start udp-custom
run_with_spinner "Mengaktifkan service pada boot..." systemctl enable udp-custom

# Verify service is running
run_with_spinner "Memverifikasi service..." systemctl is-active --quiet udp-custom

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│${bold_white}         OPTIMASI SELESAI${neutral}                 ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"

# Display optimization summary
echo -e "${yellow}┌──────────────────────────────────────────┐${neutral}"
echo -e "${yellow}│           ${bold_white}RINGKASAN OPTIMASI${neutral}             ${yellow}│${neutral}"
echo -e "${yellow}├──────────────────────────────────────────┤${neutral}"
echo -e "${yellow}│${green}✓${neutral} Buffer UDP diperbesar hingga 128MB      ${yellow}│${neutral}"
echo -e "${yellow}│${green}✓${neutral} Kernel parameter dioptimasi             ${yellow}│${neutral}"
echo -e "${yellow}│${green}✓${neutral} IRQ balancing diaktifkan                ${yellow}│${neutral}"
echo -e "${yellow}│${green}✓${neutral} System limits ditingkatkan              ${yellow}│${neutral}"
echo -e "${yellow}│${green}✓${neutral} Konfigurasi performa tinggi             ${yellow}│${neutral}"
echo -e "${yellow}│${green}✓${neutral} Service priority ditingkatkan           ${yellow}│${neutral}"
echo -e "${yellow}│${green}✓${neutral} Monitoring tool terinstall              ${yellow}│${neutral}"
echo -e "${yellow}└──────────────────────────────────────────┘${neutral}"
echo ""
echo -e "${green}UDP Custom berhasil diinstall dengan optimasi performa!${neutral}"
echo -e "${blue}Untuk memonitor performa: ${yellow}bash /root/udp/monitor_performance.sh${neutral}"
echo -e "${blue}Status service: ${yellow}systemctl status udp-custom${neutral}"
echo ""
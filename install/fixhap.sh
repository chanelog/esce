#!/bin/bash
# HAProxy Fixer Script
# Version: 1.0
# Author: PEYX TUNNEL

# ==================== KONFIGURASI WARNA ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

MODERN_CYAN="\033[38;2;0;255;255m"
MODERN_PURPLE="\033[38;2;156;0;255m"
MODERN_GREEN="\033[38;2;0;255;128m"
MODERN_RED="\033[38;2;255;50;50m"
MODERN_ORANGE="\033[38;2;255;128;0m"
MODERN_DIM="\033[2m"
MODERN_BOLD="\033[1m"
RESET_ALL="\033[0m"

SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
CHECK_ICON="✓"
CROSS_ICON="✗"

# ==================== FUNGSI ====================

show_loading_animation() {
    local pid=$1
    local message=$2
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r${MODERN_CYAN}${SPINNER[$i]}${RESET_ALL} ${MODERN_DIM}${message}...${RESET_ALL}"
        i=$(( (i+1) % 10 ))
        sleep 0.1
    done
    printf "\r\033[K"
}

run_task() {
    local message="$1"
    local command="$2"
    
    printf "${MODERN_CYAN}◐${RESET_ALL} ${MODERN_DIM}${message}...${RESET_ALL}"
    
    bash -c "$command" &>/tmp/haproxy_fix.log &
    local task_pid=$!
    
    show_loading_animation $task_pid "$message"
    wait $task_pid
    
    if [ $? -eq 0 ]; then
        printf "\r${MODERN_GREEN}${CHECK_ICON}${RESET_ALL} ${MODERN_BOLD}${message}${RESET_ALL} ${MODERN_GREEN}${CHECK_ICON}${RESET_ALL}\n"
        return 0
    else
        printf "\r${MODERN_RED}${CROSS_ICON}${RESET_ALL} ${MODERN_BOLD}${message}${RESET_ALL} ${MODERN_RED}${CROSS_ICON}${RESET_ALL}\n"
        return 1
    fi
}

print_section_header() {
    local title="$1"
    echo ""
    echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
    echo -e "${MODERN_BOLD}${WHITE}  ${title}${RESET_ALL}"
    echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
}

print_success() {
    echo -e "${MODERN_GREEN}  ${CHECK_ICON}${RESET_ALL} ${MODERN_BOLD}$1${RESET_ALL}"
}

print_error() {
    echo -e "${MODERN_RED}  ${CROSS_ICON}${RESET_ALL} ${MODERN_BOLD}$1${RESET_ALL}"
}

print_info() {
    echo -e "${MODERN_CYAN}  •${RESET_ALL} $1"
}

print_warning() {
    echo -e "${MODERN_ORANGE}  ⚠${RESET_ALL} ${MODERN_BOLD}$1${RESET_ALL}"
}

# ==================== CEK ROOT ====================
if [[ $EUID -ne 0 ]]; then
    print_error "Script harus dijalankan sebagai root!"
    exit 1
fi

# ==================== MAIN ====================
clear
echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
echo -e "${MODERN_BOLD}${WHITE}           HAPROXY FIXER SCRIPT v1.0${RESET_ALL}"
echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
echo ""

# ==================== STOP HAPROXY ====================
print_section_header "🛑 STOPPING HAPROXY"
run_task "Stopping HAProxy service" "systemctl stop haproxy"

# ==================== BACKUP CONFIG LAMA ====================
print_section_header "💾 BACKUP CONFIGURATION"
if [ -f /etc/haproxy/haproxy.cfg ]; then
    backup_file="/etc/haproxy/haproxy.cfg.bak.$(date +%Y%m%d-%H%M%S)"
    run_task "Backup old config" "cp /etc/haproxy/haproxy.cfg $backup_file"
    print_info "Backup saved to: $backup_file"
fi

# ==================== AMBIL DOMAIN ====================
print_section_header "🌐 GETTING DOMAIN"
domain=""
if [ -f /etc/xray/domain ]; then
    domain=$(cat /etc/xray/domain)
    print_info "Domain found: $domain"
else
    domain="localhost"
    print_warning "Domain not found, using localhost"
fi

# ==================== BUAT FILE PEM ====================
print_section_header "🔐 CREATING PEM FILE"

# Cek apakah file certificate ada
if [ -f /etc/xray/xray.crt ] && [ -f /etc/xray/xray.key ]; then
    run_task "Using existing certificate" "cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem"
    print_success "PEM created from /etc/xray certificate"
else
    print_info "Certificate not found, creating self-signed..."
    run_task "Creating self-signed certificate" "openssl req -x509 -newkey rsa:4096 -keyout /etc/haproxy/hap.key -out /etc/haproxy/hap.crt -days 365 -nodes -subj '/CN=$domain' 2>/dev/null"
    run_task "Creating PEM file" "cat /etc/haproxy/hap.crt /etc/haproxy/hap.key > /etc/haproxy/hap.pem"
    print_success "Self-signed PEM created"
fi

run_task "Setting PEM permissions" "chmod 644 /etc/haproxy/hap.pem"

# ==================== BUAT KONFIGURASI HAPROXY ====================
print_section_header "⚙️ CREATING HAPROXY CONFIG"

cat > /etc/haproxy/haproxy.cfg << 'EOF'
# CFG LOADBALANCER PX STORE
global       
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    
    tune.h2.initial-window-size 2147483647
    tune.ssl.default-dh-param 2048

    pidfile /run/haproxy.pid
    chroot /var/lib/haproxy

    user haproxy
    group haproxy
    daemon

    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11

    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

defaults
    log global
    mode tcp
    option dontlognull
    timeout connect 60s
    timeout client 300s
    timeout server 300s

frontend http_frontend
    mode tcp
    bind *:80
    bind *:8080
    bind *:8880
    bind *:2080
    bind *:2082
    
    tcp-request inspect-delay 500ms
    tcp-request content accept if HTTP
    acl is_websocket hdr(Upgrade) -i websocket

    use_backend ws_backend if is_websocket
    default_backend dropbear_backend

frontend https_frontend
    bind *:443 ssl crt /etc/haproxy/hap.pem
    mode tcp
    tcp-request inspect-delay 500ms
    tcp-request content accept if { req.ssl_hello_type 1 }

    acl is_websocket_ssl hdr(Upgrade) -i websocket
    use_backend ws_backend if is_websocket_ssl
    default_backend dropbear_backend

backend dropbear_backend
    mode tcp
    server dropbear_server 127.0.0.1:58080 check inter 3000 rise 2 fall 3

backend ws_backend
    mode tcp
    server ws_server 127.0.0.1:1010 check inter 3000 rise 2 fall 3
EOF

print_success "HAProxy configuration created"

# ==================== TEST KONFIGURASI ====================
print_section_header "🔍 TESTING CONFIGURATION"

if haproxy -c -f /etc/haproxy/haproxy.cfg 2>/dev/null; then
    print_success "Configuration is valid"
else
    print_warning "Configuration test failed, using minimal config..."
    
    # Konfigurasi minimal sebagai fallback
    cat > /etc/haproxy/haproxy.cfg << EOF
global
    daemon
    user haproxy
    group haproxy

defaults
    mode tcp
    timeout connect 5000
    timeout client 50000
    timeout server 50000

frontend http_in
    bind *:80
    default_backend xray_ws

frontend https_in
    bind *:443 ssl crt /etc/haproxy/hap.pem
    default_backend xray_ws

backend xray_ws
    server xray 127.0.0.1:1010 check
EOF
    
    if haproxy -c -f /etc/haproxy/haproxy.cfg 2>/dev/null; then
        print_success "Minimal configuration is valid"
    else
        print_error "Both configurations failed!"
        exit 1
    fi
fi

# ==================== START HAPROXY ====================
print_section_header "🚀 STARTING HAPROXY"

run_task "Enabling HAProxy service" "systemctl enable haproxy"
run_task "Starting HAProxy service" "systemctl start haproxy"

sleep 2

# ==================== CEK STATUS ====================
print_section_header "📊 STATUS CHECK"

if systemctl is-active --quiet haproxy; then
    print_success "HAProxy is running"
    
    # Tampilkan port yang dibuka
    echo ""
    print_info "Active ports:"
    netstat -tlnp 2>/dev/null | grep haproxy | awk '{print "  • " $4}' | sort -u
else
    print_error "HAProxy failed to start"
    echo ""
    print_info "Error log:"
    journalctl -u haproxy --no-pager -n 20
    exit 1
fi

# ==================== CEK PORTS ====================
echo ""
print_section_header "🔌 PORT CHECK"

ports="80 443 8080 8880 2080 2082"
for port in $ports; do
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        print_success "Port $port is listening"
    else
        print_warning "Port $port is not listening"
    fi
done

# ==================== CEK DROPBEAR ====================
echo ""
if netstat -tlnp 2>/dev/null | grep -q ":58080 "; then
    print_success "Dropbear (port 58080) is running"
else
    print_warning "Dropbear (port 58080) is not running"
    print_info "Make sure Dropbear is installed and running on port 58080"
fi

# ==================== SUMMARY ====================
echo ""
print_section_header "✅ HAPROXY FIX COMPLETED"
print_info "Config file: /etc/haproxy/haproxy.cfg"
print_info "PEM file: /etc/haproxy/hap.pem"
print_info "Backup saved to: $backup_file"
echo ""
print_section_header "📝 USEFUL COMMANDS"
print_info "systemctl status haproxy  - Check HAProxy status"
print_info "systemctl restart haproxy - Restart HAProxy"
print_info "journalctl -u haproxy -f  - View real-time logs"
print_info "haproxy -c -f /etc/haproxy/haproxy.cfg - Test configuration"
echo ""

print_success "HAProxy fix completed successfully!"
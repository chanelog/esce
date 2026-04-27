#!/bin/bash
# Xray Mod PX Installer Script
# Version: 3.0 - Mod PX (Self-Signed SSL)
# Author: PEYX TUNNEL

# ==================== KONFIGURASI WARNA MODERN ====================
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

# ==================== KONFIGURASI GLOBAL ====================
REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
XRAY_LOG="/var/log/xray"
DOMAIN_FILE="/etc/xray/domain"
PEYX_DIR="/etc/peyx"
BACKUP_DIR="/root/xray-backup-$(date +%Y%m%d-%H%M%S)"

# ==================== FUNGSI MODERN LOADING ====================

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
    
    bash -c "$command" &>/tmp/xray_install.log &
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

# ==================== FUNGSI UTILITY ====================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script harus dijalankan sebagai root!"
        exit 1
    fi
}

check_command() {
    command -v "$1" &>/dev/null
}

# ==================== FUNGSI DOMAIN ====================

get_domain() {
    if [[ -f $DOMAIN_FILE ]]; then
        domain=$(cat $DOMAIN_FILE)
        print_info "Domain found: $domain"
    else
        print_error "Domain file not found at $DOMAIN_FILE"
        exit 1
    fi
}

# ==================== FUNGSI INSTALLASI ====================

install_dependencies() {
    print_section_header "📦 INSTALLING DEPENDENCIES"
    
    run_task "Updating package list" "apt update -y"
    run_task "Installing iptables" "apt install iptables iptables-persistent -y"
    run_task "Installing chrony & ntpdate" "apt install chrony ntpdate -y"
    run_task "Setting ntpdate" "ntpdate pool.ntp.org"
    run_task "Setting timedatectl" "timedatectl set-ntp true"
    run_task "Enabling chrony" "systemctl enable chrony && systemctl restart chrony"
    run_task "Setting timezone" "timedatectl set-timezone Asia/Jakarta"
    run_task "Installing core packages" "apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y"
    run_task "Installing additional packages" "apt install socat cron bash-completion zip pwgen openssl net-tools jq -y"
    
    print_success "Dependencies installed"
}

create_directories() {
    print_section_header "📁 CREATING DIRECTORIES"
    
    local domainSock_dir="/run/xray"
    if [ ! -d "$domainSock_dir" ]; then
        run_task "Creating /run/xray" "mkdir -p $domainSock_dir"
    fi
    
    run_task "Setting ownership" "chown www-data.www-data $domainSock_dir"
    run_task "Creating /var/log/xray" "mkdir -p $XRAY_LOG"
    run_task "Creating /etc/xray" "mkdir -p /etc/xray"
    run_task "Creating /usr/local/etc/xray" "mkdir -p /usr/local/etc/xray"
    run_task "Creating PEYX directories" "mkdir -p $PEYX_DIR/{vmess,vless,trojan,limit/{vmess,vless,trojan}/ip,log}"
    run_task "Setting permissions" "chown -R www-data:www-data $XRAY_LOG && chmod +x $XRAY_LOG"
    run_task "Creating log files" "touch $XRAY_LOG/access.log $XRAY_LOG/error.log"
    
    print_success "Directories created"
}

install_xray_core() {
    print_section_header "🚀 INSTALLING XRAY MOD PX"
    
    local latest_version="24.11.30"
    run_task "Downloading Xray core v$latest_version" "bash -c \"\$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)\" @ install -u www-data --version $latest_version"
    
    if check_command xray; then
        print_success "Xray core installed"
        local xray_version=$(xray version 2>/dev/null | head -1)
        print_info "Version: $xray_version"
    else
        print_error "Failed to install Xray core"
        exit 1
    fi
}

install_nginx() {
    print_section_header "🌐 INSTALLING NGINX"
    
    if ! check_command nginx; then
        run_task "Installing Nginx" "apt install nginx -y"
        print_success "Nginx installed"
    else
        print_success "Nginx already installed"
    fi
}

# ==================== SSL CERTIFICATE (SELF-SIGNED) ====================

setup_ssl_certificate() {
    print_section_header "🔐 SETUP SSL CERTIFICATE (SELF-SIGNED)"
    
    # Stop services yang menggunakan port 80/443
    run_task "Stopping nginx" "systemctl stop nginx"
    
    # Backup certificate lama jika ada
    if [ -f /etc/xray/xray.key ]; then
        run_task "Backup old certificate" "cp /etc/xray/xray.key /etc/xray/xray.key.bak"
    fi
    if [ -f /etc/xray/xray.crt ]; then
        run_task "Backup old certificate" "cp /etc/xray/xray.crt /etc/xray/xray.crt.bak"
    fi
    
    # Generate self-signed certificate dengan OpenSSL
    print_info "Generating self-signed SSL certificate for $domain"
    
    run_task "Creating SSL certificate" "openssl req -x509 -newkey rsa:4096 -keyout /etc/xray/xray.key -out /etc/xray/xray.crt -days 365 -nodes -subj '/C=ID/ST=Jawa Barat/L=Sukabumi/O=PeyxDev/CN=$domain' 2>/dev/null"
    
    # Set permissions
    run_task "Setting certificate permissions" "chmod 644 /etc/xray/xray.crt && chmod 640 /etc/xray/xray.key"
    
    print_success "SSL certificate generated successfully"
}

# ==================== XRAY CONFIGURATION ====================

generate_xray_config() {
    print_section_header "⚙️ GENERATING XRAY CONFIG"
    
    local uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "1d1c1d94-6987-4658-a4dc-8821a30fe7e0")
    print_info "Generated UUID: $uuid"
    
    cat > "$XRAY_CONFIG" << EOF
{
  "log": {
    "access": "$XRAY_LOG/access.log",
    "error": "$XRAY_LOG/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10000,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
    {
      "listen": "127.0.0.1",
      "port": 10001,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid",
            "email": "vless1"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      },
      "tag": "vless-ws"
    },
    {
      "listen": "127.0.0.1",
      "port": 10002,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 0,
            "email": "vmess1"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess"
        }
      },
      "tag": "vmess-ws"
    },
    {
      "listen": "127.0.0.1",
      "port": 10003,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$uuid",
            "email": "trojan1"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojan"
        }
      },
      "tag": "trojan-ws"
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "protocol": ["bittorrent"],
        "outboundTag": "blocked"
      }
    ]
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserUplink": true,
        "statsUserDownlink": true
      }
    }
  },
  "stats": {},
  "api": {
    "services": ["StatsService"],
    "tag": "api"
  }
}
EOF

    # Buat file database default
    echo "### vmess1 $(date -d '30 days' +%Y-%m-%d) $uuid 10 2" >> "$PEYX_DIR/vmess.db"
    echo "### vless1 $(date -d '30 days' +%Y-%m-%d) $uuid 10 2" >> "$PEYX_DIR/vless.db"
    echo "### trojan1 $(date -d '30 days' +%Y-%m-%d) $uuid 10 2" >> "$PEYX_DIR/trojan.db"
    
    echo "2" > "$PEYX_DIR/limit/vmess/ip/vmess1"
    echo "2" > "$PEYX_DIR/limit/vless/ip/vless1"
    echo "2" > "$PEYX_DIR/limit/trojan/ip/trojan1"
    
    print_success "Xray configuration generated"
}

# ==================== NGINX CONFIGURATION ====================

configure_nginx() {
    print_section_header "🌐 CONFIGURING NGINX"
    
    # Buat konfigurasi nginx manual
    cat > /etc/nginx/conf.d/xray.conf << EOF
server {
    listen 80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;
    
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    location /vmess {
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    
    location /vless {
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    
    location /trojan {
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    
    location /status {
        return 200 "OK";
        add_header Content-Type text/plain;
    }
}
EOF

    run_task "Testing nginx config" "nginx -t"
    run_task "Restarting nginx" "systemctl restart nginx"
    
    print_success "Nginx configured"
}

# ==================== SERVICE CONFIGURATION ====================

create_xray_service() {
    print_section_header "🔧 CREATING XRAY SERVICE"
    
    cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    run_task "Reloading systemd" "systemctl daemon-reload"
    run_task "Enabling xray service" "systemctl enable xray"
    run_task "Starting xray service" "systemctl start xray"
    
    sleep 2
    
    if systemctl is-active --quiet xray; then
        print_success "Xray service is running"
    else
        print_error "Xray service failed to start"
        journalctl -u xray --no-pager -n 20
        exit 1
    fi
}

create_monitoring_script() {
    print_section_header "📊 CREATING MONITORING SCRIPT"
    
    cat > /usr/local/bin/cek-xray << 'EOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}         XRAY STATUS MONITOR${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Service Status:${NC}"
for service in xray nginx; do
    if systemctl is-active --quiet $service; then
        echo -e "  ${GREEN}✓ $service: Running${NC}"
    else
        echo -e "  ${RED}✗ $service: Stopped${NC}"
    fi
done

echo ""
echo -e "${YELLOW}Port Status:${NC}"
for port in 80 443 10001 10002 10003; do
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        echo -e "  ${GREEN}✓ Port $port: Active${NC}"
    else
        echo -e "  ${RED}✗ Port $port: Inactive${NC}"
    fi
done

echo ""
echo -e "${YELLOW}User Statistics:${NC}"
for service in vmess vless trojan; do
    if [[ -f /etc/peyx/$service.db ]]; then
        count=$(grep -c "^###" /etc/peyx/$service.db 2>/dev/null || echo "0")
        echo -e "  ${CYAN}› $service: $count users${NC}"
    fi
done
echo -e "${BLUE}════════════════════════════════════════${NC}"
EOF

    run_task "Setting monitoring script permission" "chmod +x /usr/local/bin/cek-xray"
    print_success "Monitoring script created"
}

create_test_endpoint() {
    print_section_header "🌍 CREATING TEST ENDPOINT"
    
    cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Xray Mod PX Server</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; background: #0a0e27; color: #fff; }
        .success { color: #00ff88; font-size: 24px; }
        .info { color: #00ccff; margin: 20px 0; }
        .container { background: #1a1f3a; padding: 30px; border-radius: 10px; max-width: 500px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="success">✓ Xray Mod PX Running</h1>
        <p class="info">Domain: $(cat /etc/xray/domain 2>/dev/null)</p>
        <p>Status: <span style="color:#00ff88">Active</span></p>
        <p>Server by: PEYX TUNNEL</p>
    </div>
</body>
</html>
EOF

    print_success "Test endpoint created"
}

# ==================== CLEANUP ====================

cleanup() {
    print_section_header "🧹 CLEANING UP"
    
    # Hapus file temporary
    rm -f /root/ins-xray.sh 2>/dev/null
    rm -f /root/xray-new.sh 2>/dev/null
    
    print_success "Cleanup completed"
}

# ==================== SUMMARY ====================

show_summary() {
    echo ""
    print_section_header "✅ INSTALLATION COMPLETE"
    print_info "Domain      : ${MODERN_GREEN}$domain${RESET_ALL}"
    print_info "Config      : ${MODERN_CYAN}$XRAY_CONFIG${RESET_ALL}"
    print_info "Logs        : ${MODERN_CYAN}$XRAY_LOG${RESET_ALL}"
    print_info "Database    : ${MODERN_CYAN}$PEYX_DIR/${RESET_ALL}"
    print_info "SSL Cert    : ${MODERN_CYAN}/etc/xray/xray.crt (Self-Signed)${RESET_ALL}"
    echo ""
    print_section_header "📝 AVAILABLE COMMANDS"
    print_info "cek-xray              - Check Xray status"
    print_info "systemctl status xray - Service details"
    print_info "journalctl -u xray -f - Real-time logs"
    print_info "nano $XRAY_CONFIG    - Edit config manually"
    echo ""
    print_section_header "🔗 TEST URL"
    print_info "https://$domain/status"
    echo ""
    print_warning "SSL menggunakan Self-Signed Certificate"
    print_info "Abaikan peringatan 'Not Secure' di browser"
}

# ==================== MAIN PROGRAM ====================

main() {
    clear
    echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
    echo -e "${MODERN_BOLD}${WHITE}           XRAY MOD PX INSTALLER v3.0${RESET_ALL}"
    echo -e "${MODERN_PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_ALL}"
    echo ""
    
    check_root
    get_domain
    
    install_dependencies
    create_directories
    install_nginx
    install_xray_core
    setup_ssl_certificate
    generate_xray_config
    configure_nginx
    create_xray_service
    create_monitoring_script
    create_test_endpoint
    cleanup
    
    show_summary
    
    # Final test
    echo -e "${MODERN_CYAN}  Running final tests...${RESET_ALL}"
    sleep 1
    
    systemctl is-active --quiet nginx && print_success "Nginx is running" || print_warning "Nginx is not running"
    systemctl is-active --quiet xray && print_success "Xray is running" || print_warning "Xray is not running"
    
    echo ""
    print_success "Xray Mod PX installation completed successfully!"
    echo ""
}

# Jalankan main function
main

# Bersihkan file instalasi
clear
rm -f ins-xray.sh 2>/dev/null
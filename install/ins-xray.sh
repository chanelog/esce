#!/bin/bash
# Xray Mod PX Installer Script
# Version: 3.0 - Auto Fix HAProxy
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
    run_task "Installing additional packages" "apt install socat cron bash-completion zip pwgen openssl net-tools jq haproxy -y"
    
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

# ==================== SSL CERTIFICATE ====================

setup_ssl_certificate() {
    print_section_header "🔐 SETUP SSL CERTIFICATE"
    
    run_task "Stopping nginx" "systemctl stop nginx"
    run_task "Stopping haproxy" "systemctl stop haproxy 2>/dev/null || true"
    
    mkdir -p /root/.acme.sh
    run_task "Downloading acme.sh" "curl -s https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh"
    run_task "Setting acme.sh permission" "chmod +x /root/.acme.sh/acme.sh"
    run_task "Upgrading acme.sh" "/root/.acme.sh/acme.sh --upgrade --auto-upgrade"
    run_task "Setting default CA" "/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt"
    run_task "Issuing SSL certificate" "/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256"
    run_task "Installing SSL certificate" "/root/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc"
    
    print_success "SSL certificate configured"
}

setup_ssl_renew() {
    print_section_header "🔄 SETUP SSL RENEW"
    
    cat > /usr/local/bin/ssl_renew.sh << 'EOF'
#!/bin/bash
/etc/init.d/nginx stop
"/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" &> /root/renew_ssl.log
/etc/init.d/nginx start
EOF
    
    run_task "Setting ssl_renew permission" "chmod +x /usr/local/bin/ssl_renew.sh"
    
    if ! grep -q 'ssl_renew.sh' /var/spool/cron/crontabs/root 2>/dev/null; then
        (crontab -l 2>/dev/null; echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab -
    fi
    
    run_task "Creating public_html" "mkdir -p /home/vps/public_html"
    
    print_success "SSL renew configured"
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
      "listen": "0.0.0.0",
      "port": 1010,
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
      "listen": "0.0.0.0",
      "port": 1020,
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
      "listen": "0.0.0.0",
      "port": 1030,
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

# ==================== HAPROXY CONFIGURATION (AUTO FIX) ====================

configure_haproxy() {
    print_section_header "🔧 CONFIGURING HAPROXY"
    
    # Buat file PEM dari certificate
    if [ -f /etc/xray/xray.crt ] && [ -f /etc/xray/xray.key ]; then
        cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem
        chmod 644 /etc/haproxy/hap.pem
        print_success "PEM file created"
    else
        print_warning "Certificate not found, creating self-signed"
        openssl req -x509 -newkey rsa:4096 -keyout /etc/haproxy/hap.key -out /etc/haproxy/hap.crt -days 365 -nodes -subj "/CN=$domain"
        cat /etc/haproxy/hap.crt /etc/haproxy/hap.key > /etc/haproxy/hap.pem
        chmod 644 /etc/haproxy/hap.pem
    fi
    
    # Buat konfigurasi HAProxy PX Store
    cat > /etc/haproxy/haproxy.cfg << 'EOF'
# CFG LOADBALANCER PX STORE
global       
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 1d
    
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
    bind *:80 tfo
    bind *:8080 tfo
    bind *:8880 tfo
    bind *:2080 tfo
    bind *:2082 tfo
    
    tcp-request inspect-delay 500ms
    tcp-request content accept if HTTP
    acl is_websocket hdr(Upgrade) -i websocket

    use_backend ws_backend if is_websocket
    default_backend dropbear_backend

frontend https_frontend
    bind *:443 ssl crt /etc/haproxy/hap.pem tfo
    mode tcp
    tcp-request inspect-delay 500ms
    tcp-request content accept if { req.ssl_hello_type 1 }

    acl is_websocket_ssl hdr(Upgrade) -i websocket
    use_backend ws_backend if is_websocket_ssl
    default_backend dropbear_backend

backend dropbear_backend
    mode tcp
    server dropbear_server 127.0.0.1:58080 check

backend ws_backend
    mode tcp
    server ws_server 127.0.0.1:1010 check
EOF

    # Test konfigurasi
    if haproxy -c -f /etc/haproxy/haproxy.cfg 2>/dev/null; then
        print_success "HAProxy configuration valid"
    else
        print_warning "Configuration test failed, using minimal config"
        # Minimal config sebagai fallback
        cat > /etc/haproxy/haproxy.cfg << EOF
global
    daemon

defaults
    mode tcp
    timeout connect 5000
    timeout client 50000
    timeout server 50000

frontend haproxy_in
    bind *:443 ssl crt /etc/haproxy/hap.pem
    mode tcp
    default_backend xray_out

backend xray_out
    mode tcp
    server xray 127.0.0.1:1010 check
EOF
    fi
    
    # Start HAProxy
    run_task "Starting HAProxy" "systemctl start haproxy"
    run_task "Enabling HAProxy" "systemctl enable haproxy"
    
    print_success "HAProxy configured"
}

# ==================== NGINX CONFIGURATION ====================

configure_nginx() {
    print_section_header "🌐 CONFIGURING NGINX"
    
    # Hentikan Nginx dulu
    systemctl stop nginx
    
    # Buat konfigurasi nginx
    cat > /etc/nginx/sites-available/xray << EOF
server {
    listen 127.0.0.1:8080;
    server_name $domain;
    
    location / {
        root /var/www/html;
        index index.html;
    }
    
    location /vmess {
        proxy_pass http://127.0.0.1:1020;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    
    location /vless {
        proxy_pass http://127.0.0.1:1010;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    
    location /trojan {
        proxy_pass http://127.0.0.1:1030;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/xray /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test dan start nginx
    nginx -t 2>/dev/null
    run_task "Starting Nginx" "systemctl start nginx"
    
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
for service in xray nginx haproxy; do
    if systemctl is-active --quiet $service; then
        echo -e "  ${GREEN}✓ $service: Running${NC}"
    else
        echo -e "  ${RED}✗ $service: Stopped${NC}"
    fi
done

echo ""
echo -e "${YELLOW}Port Status:${NC}"
for port in 80 443 1010 1020 1030 8080; do
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        echo -e "  ${GREEN}✓ Port $port: Active${NC}"
    else
        echo -e "  ${RED}✗ Port $port: Inactive${NC}"
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
    echo ""
    print_section_header "📝 AVAILABLE COMMANDS"
    print_info "cek-xray              - Check all services status"
    print_info "systemctl status xray - Xray service details"
    print_info "systemctl status haproxy - HAProxy details"
    echo ""
    print_section_header "🔗 SERVICES"
    print_info "HTTP Proxy   : port 80, 8080, 8880, 2080, 2082"
    print_info "HTTPS Proxy  : port 443"
    print_info "XRay VLess WS : port 1010"
    print_info "XRay VMess WS : port 1020"
    print_info "XRay Trojan WS: port 1030"
    echo ""
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
    setup_ssl_renew
    generate_xray_config
    configure_nginx
    create_xray_service
    configure_haproxy
    create_monitoring_script
    create_test_endpoint
    cleanup
    
    show_summary
    
    # Final test
    echo -e "${MODERN_CYAN}  Running final tests...${RESET_ALL}"
    sleep 1
    
    systemctl is-active --quiet nginx && print_success "Nginx is running" || print_warning "Nginx is not running"
    systemctl is-active --quiet xray && print_success "Xray is running" || print_warning "Xray is not running"
    systemctl is-active --quiet haproxy && print_success "HAProxy is running" || print_warning "HAProxy is not running"
    
    echo ""
    print_success "Xray Mod PX installation completed successfully!"
    echo ""
}

# Jalankan main function
main

# Bersihkan file instalasi
clear
rm -f ins-xray.sh 2>/dev/null
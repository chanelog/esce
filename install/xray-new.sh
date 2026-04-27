#!/bin/bash
# Xray Ultimate Installer Script
# Version: 2.0 - Fresh Install Fix
# Author: PEYX TUNNEL

# ==================== KONFIGURASI WARNA ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ==================== KONFIGURASI GLOBAL ====================
XRAY_CONFIG="/usr/local/etc/xray/config.json"
XRAY_LOG="/var/log/xray"
DOMAIN_FILE="/etc/xray/domain"
PEYX_DIR="/etc/peyx"
BACKUP_DIR="/root/xray-backup-$(date +%Y%m%d-%H%M%S)"

# ==================== FUNGSI UTILITY ====================

print_banner() {
    clear
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${GREEN}        XRAY ULTIMATE INSTALLER${NC}"
    echo -e "${CYAN}           Version 2.0${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}➜ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script harus dijalankan sebagai root!"
        exit 1
    fi
}

check_command() {
    command -v $1 &>/dev/null
}

create_directories() {
    print_info "Membuat struktur direktori..."
    
    mkdir -p $PEYX_DIR/{vmess,vless,trojan,limit/{vmess,vless,trojan}/ip,log}
    mkdir -p /usr/local/etc/xray
    mkdir -p $XRAY_LOG
    mkdir -p /etc/xray
    mkdir -p /etc/nginx/sites-{available,enabled}
    
    chown -R www-data:www-data $XRAY_LOG 2>/dev/null
    chmod 755 $PEYX_DIR
    
    print_success "Struktur direktori selesai"
}

# ==================== FUNGSI DOMAIN ====================

input_domain() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}            INPUT DOMAIN ANDA${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Cek apakah sudah ada domain sebelumnya
    if [[ -f $DOMAIN_FILE ]]; then
        current_domain=$(cat $DOMAIN_FILE)
        echo -e "${CYAN}Domain saat ini: ${GREEN}$current_domain${NC}"
        echo -ne "${YELLOW}Gunakan domain ini? (y/n, default y): ${NC}"
        read use_current
        if [[ "$use_current" == "n" || "$use_current" == "N" ]]; then
            use_current="n"
        else
            use_current="y"
        fi
    fi
    
    if [[ "$use_current" != "y" ]]; then
        echo ""
        echo -e "${CYAN}Masukkan domain Anda (contoh: panel.domain.com)${NC}"
        echo -ne "${GREEN}Domain: ${NC}"
        read domain
        
        while [[ -z "$domain" ]]; do
            print_error "Domain tidak boleh kosong!"
            echo -ne "${GREEN}Domain: ${NC}"
            read domain
        done
        
        # Simpan domain
        echo "$domain" > $DOMAIN_FILE
        print_success "Domain saved: $domain"
    else
        domain=$current_domain
        print_success "Menggunakan domain: $domain"
    fi
    
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ==================== FUNGSI BACKUP ====================

backup_old_data() {
    print_info "Memulai backup data lama..."
    
    mkdir -p $BACKUP_DIR
    
    if [[ -d "/etc/kyt" ]]; then
        cp -r /etc/kyt $BACKUP_DIR/kyt 2>/dev/null
        print_success "Backup kyt selesai"
    fi
    
    for db in vmess vless trojan; do
        if [[ -f "/etc/$db/.$db.db" ]]; then
            cp "/etc/$db/.$db.db" $BACKUP_DIR/ 2>/dev/null
            print_success "Backup $db database selesai"
        fi
    done
    
    print_success "Backup selesai di: $BACKUP_DIR"
}

remove_old_installation() {
    print_warning "Menghapus instalasi Xray lama..."
    
    # Stop services
    systemctl stop xray nginx 2>/dev/null
    systemctl disable xray 2>/dev/null
    
    # Remove Xray config
    rm -rf /usr/local/etc/xray
    rm -rf /var/log/xray
    rm -f /etc/systemd/system/xray.service
    rm -f /etc/systemd/system/xray@.service
    
    # Remove old directories
    rm -rf /etc/kyt 2>/dev/null
    rm -rf /etc/vmess 2>/dev/null
    rm -rf /etc/vless 2>/dev/null
    rm -rf /etc/trojan 2>/dev/null
    
    # Remove nginx config
    rm -f /etc/nginx/sites-available/xray 2>/dev/null
    rm -f /etc/nginx/sites-enabled/xray 2>/dev/null
    
    # Uninstall Xray core if exists
    if check_command xray; then
        print_info "Menghapus Xray core yang lama..."
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge 2>/dev/null
    fi
    
    pkill -f xray 2>/dev/null
    
    print_success "Instalasi lama dihapus"
}

# ==================== FUNGSI INSTALLASI ====================

install_xray_core() {
    print_info "Menginstall Xray Core..."
    
    # Install Xray core
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    if [[ $? -eq 0 ]] && check_command xray; then
        print_success "Xray Core terinstall"
        xray_version=$(xray version | head -1)
        print_info "Version: $xray_version"
    else
        print_error "Gagal install Xray Core"
        exit 1
    fi
}

install_nginx() {
    print_info "Menginstall/Update Nginx..."
    
    if ! check_command nginx; then
        apt update -y
        apt install nginx -y
        print_success "Nginx terinstall"
    else
        print_success "Nginx sudah terinstall"
    fi
}

install_dependencies() {
    print_info "Menginstall dependencies..."
    
    apt update -y
    apt install -y curl wget jq openssl net-tools socat cron at
    
    print_success "Dependencies selesai"
}

create_ssl_certificate() {
    print_info "Membuat SSL Certificate..."
    
    # Backup jika ada
    [ -f /etc/xray/xray.key ] && cp /etc/xray/xray.key /etc/xray/xray.key.bak
    [ -f /etc/xray/xray.crt ] && cp /etc/xray/xray.crt /etc/xray/xray.crt.bak
    
    # Buat self-signed certificate
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=ID/ST=Jawa Barat/L=Sukabumi/O=PEYX TUNNEL/CN=$domain" \
        -keyout /etc/xray/xray.key \
        -out /etc/xray/xray.crt 2>/dev/null
    
    chmod 644 /etc/xray/xray.{crt,key}
    print_success "SSL Certificate selesai"
}

generate_config() {
    print_info "Membuat konfigurasi Xray..."
    
    # Generate UUID untuk default
    uuid_vmess=$(cat /proc/sys/kernel/random/uuid)
    uuid_vless=$(cat /proc/sys/kernel/random/uuid)
    pass_trojan=$(cat /proc/sys/kernel/random/uuid)
    
    cat > $XRAY_CONFIG << 'EOF'
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
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
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      },
      "tag": "vless"
    },
    {
      "listen": "127.0.0.1",
      "port": 10002,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess"
        }
      },
      "tag": "vmess"
    },
    {
      "listen": "127.0.0.1",
      "port": 10003,
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojan"
        }
      },
      "tag": "trojan"
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
    
    print_success "Konfigurasi Xray selesai"
}

# ==================== FUNGSI NGINX ====================

configure_nginx() {
    print_info "Mengkonfigurasi Nginx..."
    
    cat > /etc/nginx/sites-available/xray << EOF
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
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    root /var/www/html;
    index index.html;
    
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
    
    # Enable site
    ln -sf /etc/nginx/sites-available/xray /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    nginx -t
    
    if [[ $? -eq 0 ]]; then
        systemctl restart nginx
        print_success "Nginx berhasil dikonfigurasi"
    else
        print_error "Konfigurasi Nginx gagal"
        nginx -t
        exit 1
    fi
}

# ==================== FUNGSI SERVICE ====================

create_xray_service() {
    print_info "Membuat service Xray..."
    
    cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
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
    
    systemctl daemon-reload
    systemctl enable xray
    systemctl start xray
    
    sleep 2
    
    if systemctl is-active --quiet xray; then
        print_success "Service Xray berjalan"
    else
        print_error "Service Xray gagal berjalan"
        systemctl status xray --no-pager
        exit 1
    fi
}

create_monitoring_script() {
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

# Service status
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

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
EOF

    chmod +x /usr/local/bin/cek-xray
    print_success "Script monitoring selesai"
}

create_test_endpoint() {
    print_info "Membuat test endpoint..."
    
    cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Xray Server</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        .success { color: green; }
    </style>
</head>
<body>
    <h1 class="success">✓ Xray Server Running</h1>
    <p>Domain: $domain</p>
    <p>Status: Active</p>
</body>
</html>
EOF
    
    print_success "Test endpoint selesai"
}

# ==================== FUNGSI UTAMA ====================

show_summary() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ INSTALLASI XRAY SELESAI!${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📋 INFORMASI INSTALLASI:${NC}"
    echo -e "   Domain        : ${GREEN}$domain${NC}"
    echo -e "   Database      : ${GREEN}$PEYX_DIR/${NC}"
    echo -e "   Limit IP      : ${GREEN}$PEYX_DIR/limit/${NC}"
    echo -e "   Konfigurasi   : ${GREEN}$XRAY_CONFIG${NC}"
    echo -e "   SSL Cert      : ${GREEN}/etc/xray/xray.crt${NC}"
    echo ""
    echo -e "${CYAN}📝 Perintah yang tersedia:${NC}"
    echo -e "   • ${GREEN}cek-xray${NC}        - Cek status Xray"
    echo -e "   • ${GREEN}systemctl status xray${NC} - Cek detail service"
    echo -e "   • ${GREEN}journalctl -u xray -f${NC} - Lihat log realtime"
    echo ""
    echo -e "${CYAN}🔗 Test URL:${NC}"
    echo -e "   • ${GREEN}https://$domain/status${NC}"
    echo ""
}

# ==================== MAIN PROGRAM ====================

main() {
    print_banner
    check_root
    
    # Install dependencies first
    install_dependencies
    
    # Input domain
    input_domain
    
    # Backup dan migrasi
    backup_old_data
    
    # Hapus instalasi lama
    remove_old_installation
    echo ""
    
    # Install baru
    create_directories
    install_nginx
    install_xray_core
    echo ""
    
    # Konfigurasi
    create_ssl_certificate
    generate_config
    echo ""
    
    # Nginx
    configure_nginx
    echo ""
    
    # Service
    create_xray_service
    create_monitoring_script
    create_test_endpoint
    echo ""
    
    # Final
    show_summary
    
    # Test connection
echo -e "${CYAN}Menjalankan test...${NC}"
sleep 2

# Check services
systemctl is-active --quiet nginx && print_success "Nginx running" || print_warning "Nginx not running"
systemctl is-active --quiet xray && print_success "Xray running" || print_warning "Xray not running"

# Check ports
netstat -tlnp 2>/dev/null | grep -q ":80" && print_success "Port 80 OK" || print_warning "Port 80 FAILED"
netstat -tlnp 2>/dev/null | grep -q ":443" && print_success "Port 443 OK" || print_warning "Port 443 FAILED"
}

# Jalankan main function
main
#!/bin/bash
# Xray Ultimate Installer Script
# Version: 2.0
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

print_menu() {
    echo -e "${CYAN}$1${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script harus dijalankan sebagai root!"
        exit 1
    fi
}

check_command() {
    if command -v $1 &>/dev/null; then
        return 0
    else
        return 1
    fi
}

create_directories() {
    print_info "Membuat struktur direktori..."
    
    # Direktori utama
    mkdir -p $PEYX_DIR/{vmess,vless,trojan,limit/{vmess,vless,trojan}/ip,log}
    mkdir -p /usr/local/etc/xray
    mkdir -p $XRAY_LOG
    mkdir -p /etc/xray
    
    # Set permission
    chown -R www-data:www-data $XRAY_LOG 2>/dev/null
    chmod 755 $PEYX_DIR
    
    print_success "Struktur direktori selesai"
}

# ==================== FUNGSI MANAJEMEN DOMAIN ====================

get_domain() {
    if [[ -f $DOMAIN_FILE ]]; then
        domain=$(cat $DOMAIN_FILE)
        print_success "Domain ditemukan: $domain"
    else
        print_warning "File domain tidak ditemukan!"
        echo -ne "${YELLOW}Masukkan domain Anda: ${NC}"
        read domain
        mkdir -p /etc/xray
        echo "$domain" > $DOMAIN_FILE
        print_success "Domain saved: $domain"
    fi
}

validate_domain() {
    local domain=$1
    if [[ -z "$domain" ]]; then
        print_error "Domain tidak boleh kosong!"
        return 1
    fi
    return 0
}

# ==================== FUNGSI BACKUP ====================

backup_old_data() {
    print_info "Memulai backup data lama..."
    
    mkdir -p $BACKUP_DIR
    
    # Backup database
    for db in vmess vless trojan; do
        [ -f "/etc/$db/.$db.db" ] && cp "/etc/$db/.$db.db" $BACKUP_DIR/ 2>/dev/null
    done
    
    # Backup limit IP
    [ -d "/etc/kyt" ] && cp -r /etc/kyt $BACKUP_DIR/kyt 2>/dev/null
    
    print_success "Backup selesai di: $BACKUP_DIR"
}

migrate_database() {
    print_info "Migrasi database ke format baru..."
    
    # Inisialisasi file database baru
    touch $PEYX_DIR/{vmess,vless,trojan}.db
    
    # Migrasi VMess
    if [ -f "/etc/vmess/.vmess.db" ]; then
        migrate_service "vmess" "/etc/vmess/.vmess.db" "###"
    fi
    
    # Migrasi VLESS
    if [ -f "/etc/vless/.vless.db" ]; then
        migrate_service "vless" "/etc/vless/.vless.db" "###"
    fi
    
    # Migrasi Trojan
    if [ -f "/etc/trojan/.trojan.db" ]; then
        migrate_service "trojan" "/etc/trojan/.trojan.db" "###"
    fi
    
    print_success "Migrasi database selesai"
}

migrate_service() {
    local service=$1
    local db_file=$2
    local prefix=$3
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^$prefix ]]; then
            echo "$line" >> $PEYX_DIR/$service.db
            user=$(echo "$line" | awk '{print $2}')
            
            # Migrate limit IP
            if [ -f "/etc/kyt/limit/$service/ip/$user" ]; then
                mkdir -p $PEYX_DIR/limit/$service/ip
                cp "/etc/kyt/limit/$service/ip/$user" $PEYX_DIR/limit/$service/ip/$user 2>/dev/null
            fi
            
            # Migrate user data
            if [ -f "/etc/$service/$user" ]; then
                cp "/etc/$service/$user" $PEYX_DIR/$service/$user 2>/dev/null
            fi
            
            print_success "  Migrasi $service: $user"
        fi
    done < $db_file
}

# ==================== FUNGSI INSTALLASI ====================

remove_old_installation() {
    print_warning "Menghapus instalasi Xray lama..."
    
    # Stop services
    systemctl stop xray nginx 2>/dev/null
    systemctl disable xray 2>/dev/null
    
    # Remove Xray
    rm -rf /usr/local/etc/xray
    rm -rf /var/log/xray
    rm -f /etc/systemd/system/xray.service
    rm -f /etc/systemd/system/xray@.service
    
    # Remove old directories
    rm -rf /etc/kyt /etc/vmess /etc/vless /etc/trojan
    
    # Remove nginx config
    rm -f /etc/nginx/sites-{available,enabled}/{xray,default}
    
    # Uninstall Xray core
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge 2>/dev/null
    
    pkill -f xray 2>/dev/null
    
    print_success "Instalasi lama dihapus"
}

install_xray_core() {
    print_info "Menginstall Xray Core..."
    
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    if [[ $? -eq 0 ]]; then
        print_success "Xray Core terinstall"
    else
        print_error "Gagal install Xray Core"
        exit 1
    fi
}

create_ssl_certificate() {
    print_info "Membuat SSL Certificate..."
    
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=ID/ST=Jawa Barat/L=Sukabumi/O=PEYX TUNNEL/CN=$domain" \
        -keyout /etc/xray/xray.key \
        -out /etc/xray/xray.crt 2>/dev/null
    
    chmod 644 /etc/xray/xray.{crt,key}
    print_success "SSL Certificate selesai"
}

generate_config() {
    print_info "Membuat konfigurasi Xray..."
    
    # Generate UUID jika database kosong
    if [[ ! -s $PEYX_DIR/vmess.db ]]; then
        uuid_vmess=$(cat /proc/sys/kernel/random/uuid)
        uuid_vless=$(cat /proc/sys/kernel/random/uuid)
        pass_trojan=$(cat /proc/sys/kernel/random/uuid)
    else
        uuid_vmess=$(head -1 $PEYX_DIR/vmess.db 2>/dev/null | awk '{print $4}')
        uuid_vless=$(head -1 $PEYX_DIR/vless.db 2>/dev/null | awk '{print $4}')
        pass_trojan=$(head -1 $PEYX_DIR/trojan.db 2>/dev/null | awk '{print $4}')
    fi
    
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
      "settings": { "address": "127.0.0.1" },
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
        "wsSettings": { "path": "/vless" }
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
        "wsSettings": { "path": "/vmess" }
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
        "wsSettings": { "path": "/trojan" }
      },
      "tag": "trojan"
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "settings": {}, "tag": "direct" },
    { "protocol": "blackhole", "settings": {}, "tag": "blocked" }
  ],
  "routing": {
    "rules": [
      { "type": "field", "ip": ["geoip:private"], "outboundTag": "blocked" }
    ]
  },
  "policy": {
    "levels": { "0": { "statsUserUplink": true, "statsUserDownlink": true } }
  },
  "stats": {},
  "api": { "services": ["StatsService"], "tag": "api" }
}
EOF
    
    print_success "Konfigurasi Xray selesai"
}

restore_users() {
    print_info "Mengembalikan user ke konfigurasi..."
    
    # Restore VMess
    if [[ -f $PEYX_DIR/vmess.db ]]; then
        restore_service "vmess" 2 "id"
    fi
    
    # Restore VLESS
    if [[ -f $PEYX_DIR/vless.db ]]; then
        restore_service "vless" 1 "id"
    fi
    
    # Restore Trojan
    if [[ -f $PEYX_DIR/trojan.db ]]; then
        restore_trojan_users
    fi
    
    print_success "User berhasil dikembalikan"
}

restore_service() {
    local service=$1
    local inbound_index=$2
    local field=$3
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^### ]]; then
            user=$(echo "$line" | awk '{print $2}')
            value=$(echo "$line" | awk '{print $4}')
            
            jq --arg value "$value" --arg user "$user" \
               ".inbounds[$inbound_index].settings.clients += [{\"$field\": \$value, \"email\": \$user}]" \
               $XRAY_CONFIG > ${XRAY_CONFIG}.tmp && \
               mv ${XRAY_CONFIG}.tmp $XRAY_CONFIG
            
            print_success "  Restore $service: $user"
        fi
    done < $PEYX_DIR/$service.db
}

restore_trojan_users() {
    while IFS= read -r line; do
        if [[ "$line" =~ ^### ]]; then
            user=$(echo "$line" | awk '{print $2}')
            password=$(echo "$line" | awk '{print $4}')
            
            jq --arg pass "$password" --arg user "$user" \
               '.inbounds[3].settings.clients += [{"password": $pass, "email": $user}]' \
               $XRAY_CONFIG > ${XRAY_CONFIG}.tmp && \
               mv ${XRAY_CONFIG}.tmp $XRAY_CONFIG
            
            print_success "  Restore trojan: $user"
        fi
    done < $PEYX_DIR/trojan.db
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
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5;
    
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
}
EOF
    
    ln -sf /etc/nginx/sites-available/xray /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test dan restart nginx
    nginx -t && systemctl restart nginx
    
    if [[ $? -eq 0 ]]; then
        print_success "Nginx berhasil dikonfigurasi"
    else
        print_error "Konfigurasi Nginx gagal"
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
    
    print_success "Service Xray selesai"
}

create_monitoring_script() {
    cat > /usr/local/bin/cek-xray << 'EOF'
#!/bin/bash
# Monitoring script for Xray

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    echo -e "   Backup lama   : ${GREEN}$BACKUP_DIR${NC}"
    echo ""
    echo -e "${CYAN}📝 Perintah yang tersedia:${NC}"
    echo -e "   • ${GREEN}cek-xray${NC}     - Cek status Xray"
    echo -e "   • ${GREEN}systemctl status xray${NC} - Cek detail service"
    echo -e "   • ${GREEN}journalctl -u xray -f${NC} - Lihat log realtime"
    echo ""
}

confirmation() {
    echo -e "${YELLOW}⚠️  PERINGATAN: Script ini akan:${NC}"
    echo "   1. Menghapus instalasi Xray lama"
    echo "   2. Menghapus folder /etc/kyt, /etc/vmess, /etc/vless, /etc/trojan"
    echo "   3. Membuat instalasi Xray baru dengan struktur /etc/peyx"
    echo "   4. Mempertahankan akun lama (akan dimigrasi ke format baru)"
    echo ""
    echo -ne "${RED}   Lanjutkan? (y/n): ${NC}"
    read confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_error "Instalasi dibatalkan"
        exit 0
    fi
}

# ==================== MAIN PROGRAM ====================

main() {
    print_banner
    check_root
    
    confirmation
    echo ""
    
    # Backup dan migrasi
    backup_old_data
    migrate_database
    echo ""
    
    # Hapus instalasi lama
    remove_old_installation
    echo ""
    
    # Install baru
    create_directories
    install_xray_core
    echo ""
    
    # Konfigurasi
    get_domain
    validate_domain $domain || exit 1
    create_ssl_certificate
    generate_config
    restore_users
    echo ""
    
    # Nginx
    configure_nginx
    echo ""
    
    # Service
    create_xray_service
    create_monitoring_script
    echo ""
    
    # Final
    show_summary
    
    # Test connection
    sleep 2
    systemctl status xray --no-pager -l
}

# Jalankan main function
main
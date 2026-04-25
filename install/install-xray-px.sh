#!/bin/bash

# ==================== XRAY NEW INSTALLER ====================
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Spinner animation
SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

show_loading() {
    local pid=$1
    local message=$2
    local i=0
    while kill -0 $pid 2>/dev/null; do
        printf "\r${CYAN}${SPINNER[$i]}${NC} ${message}..."
        i=$(( (i+1) % 10 ))
        sleep 0.1
    done
    printf "\r\033[K"
}

run_task() {
    local message="$1"
    local command="$2"
    printf "${CYAN}◐${NC} ${message}..."
    bash -c "$command" &>/tmp/xray_install.log &
    local task_pid=$!
    show_loading $task_pid "$message"
    wait $task_pid
    if [ $? -eq 0 ]; then
        printf "\r${GREEN}✓${NC} ${message} ${GREEN}✓${NC}\n"
        return 0
    else
        printf "\r${RED}✗${NC} ${message} ${RED}✗${NC}\n"
        return 1
    fi
}

print_header() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}           🚀 XRAY INSTALLER (PEYX STYLE)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}  ✓${NC} $1"
}

print_error() {
    echo -e "${RED}  ✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}  •${NC} $1"
}

# ==================== MAIN INSTALLATION ====================
print_header

# Cek root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Script must be run as root!${NC}"
    exit 1
fi

# Ambil domain dari /etc/xray/domain
if [[ -f /etc/xray/domain ]]; then
    domain=$(cat /etc/xray/domain)
    print_info "Domain from /etc/xray/domain: $domain"
else
    echo -e "${RED}❌ Domain file not found at /etc/xray/domain${NC}"
    echo -ne "${CYAN}Enter domain manually: ${NC}"
    read -p "" domain
    while [[ -z "$domain" ]]; do
        echo -e "${RED}Domain cannot be empty!${NC}"
        echo -ne "${CYAN}Enter domain: ${NC}"
        read -p "" domain
    done
    # Simpan domain ke file
    mkdir -p /etc/xray
    echo "$domain" > /etc/xray/domain
    print_info "Domain saved to /etc/xray/domain"
fi

# ==================== CLEAN OLD ====================
run_task "Stopping old services" "systemctl stop xray 2>/dev/null; systemctl disable xray 2>/dev/null"
run_task "Cleaning old configurations" "rm -rf /usr/local/etc/xray /var/log/xray /etc/systemd/system/xray.service /etc/peyx 2>/dev/null"

# ==================== INSTALL XRAY CORE ====================
run_task "Installing Xray Core" "bash -c \"\$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)\" @ install"

# ==================== CREATE PEYX STRUCTURE ====================
run_task "Creating /etc/peyx folder structure" "mkdir -p /etc/peyx/limit/{vmess,vless,trojan}/ip && mkdir -p /etc/peyx/{vmess,vless,trojan} && mkdir -p /etc/peyx/log && mkdir -p /etc/peyx/config"

run_task "Creating user databases" "touch /etc/peyx/vmess.db /etc/peyx/vless.db /etc/peyx/trojan.db && chmod 644 /etc/peyx/*.db"

run_task "Creating default configs" "echo '100' > /etc/peyx/config/default_quota && echo '2' > /etc/peyx/config/default_ip_limit && echo '30' > /etc/peyx/config/default_duration"

# ==================== GENERATE SSL CERTIFICATE ====================
run_task "Generating SSL certificate" "
mkdir -p /etc/xray
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj '/C=ID/ST=Jawa Barat/L=Sukabumi/O=PEYX TUNNEL/OU=IT Department/CN=$domain' \
    -keyout /etc/xray/xray.key \
    -out /etc/xray/xray.crt 2>/dev/null
chmod 644 /etc/xray/xray.crt /etc/xray/xray.key
"

# ==================== CREATE XRAY CONFIG ====================
uuid_vmess="1d1c1d94-6987-4658-a4dc-8821a30fe7e0"
uuid_vless="1d1c1d94-6987-4658-a4dc-8821a30fe7e0"
pass_trojan="1d1c1d94-6987-4658-a4dc-8821a30fe7e0"

run_task "Creating Xray configuration" "
mkdir -p /usr/local/etc/xray
cat > /usr/local/etc/xray/config.json << 'XEOF'
{
  \"log\": {
    \"access\": \"/var/log/xray/access.log\",
    \"error\": \"/var/log/xray/error.log\",
    \"loglevel\": \"warning\"
  },
  \"inbounds\": [
    {
      \"listen\": \"127.0.0.1\",
      \"port\": 10000,
      \"protocol\": \"dokodemo-door\",
      \"settings\": { \"address\": \"127.0.0.1\" },
      \"tag\": \"api\"
    },
    {
      \"listen\": \"127.0.0.1\",
      \"port\": 10001,
      \"protocol\": \"vless\",
      \"settings\": {
        \"decryption\": \"none\",
        \"clients\": [
          { \"id\": \"$uuid_vless\", \"email\": \"vless1\" }
        ]
      },
      \"streamSettings\": {
        \"network\": \"ws\",
        \"wsSettings\": { \"path\": \"/vless\" }
      },
      \"tag\": \"vless\"
    },
    {
      \"listen\": \"127.0.0.1\",
      \"port\": 10002,
      \"protocol\": \"vmess\",
      \"settings\": {
        \"clients\": [
          { \"id\": \"$uuid_vmess\", \"alterId\": 0, \"email\": \"vmess1\" }
        ]
      },
      \"streamSettings\": {
        \"network\": \"ws\",
        \"wsSettings\": { \"path\": \"/vmess\" }
      },
      \"tag\": \"vmess\"
    },
    {
      \"listen\": \"127.0.0.1\",
      \"port\": 10003,
      \"protocol\": \"trojan\",
      \"settings\": {
        \"clients\": [
          { \"password\": \"$pass_trojan\", \"email\": \"trojan1\" }
        ]
      },
      \"streamSettings\": {
        \"network\": \"ws\",
        \"wsSettings\": { \"path\": \"/trojan\" }
      },
      \"tag\": \"trojan\"
    }
  ],
  \"outbounds\": [
    { \"protocol\": \"freedom\", \"settings\": {}, \"tag\": \"direct\" },
    { \"protocol\": \"blackhole\", \"settings\": {}, \"tag\": \"blocked\" }
  ]
}
XEOF
"

# ==================== CREATE XRAY SERVICE ====================
run_task "Creating Xray service" "
cat > /etc/systemd/system/xray.service << 'SEOF'
[Unit]
Description=Xray Service
After=network.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
SEOF
systemctl daemon-reload
"

# ==================== SETUP LOGS ====================
run_task "Setting up Xray logs" "mkdir -p /var/log/xray && touch /var/log/xray/access.log /var/log/xray/error.log && chown -R www-data:www-data /var/log/xray"

# ==================== START SERVICES ====================
run_task "Starting Xray service" "systemctl enable xray && systemctl start xray"

# ==================== SAVE DEFAULT USERS ====================
echo "### vmess1 $(date -d '30 days' +%Y-%m-%d) $uuid_vmess 10 2" >> /etc/peyx/vmess.db
echo "### vless1 $(date -d '30 days' +%Y-%m-%d) $uuid_vless 10 2" >> /etc/peyx/vless.db
echo "### trojan1 $(date -d '30 days' +%Y-%m-%d) $pass_trojan 10 2" >> /etc/peyx/trojan.db

echo "2" > /etc/peyx/limit/vmess/ip/vmess1
echo "2" > /etc/peyx/limit/vless/ip/vless1
echo "2" > /etc/peyx/limit/trojan/ip/trojan1

# ==================== CHECK STATUS ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}                    STATUS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if systemctl is-active --quiet xray; then
    echo -e "${GREEN}  ✅ Xray Service: Running${NC}"
else
    echo -e "${RED}  ❌ Xray Service: Not Running${NC}"
fi

echo -e "${CYAN}  📁 Config: /usr/local/etc/xray/config.json${NC}"
echo -e "${CYAN}  📁 Data: /etc/peyx/${NC}"
echo -e "${CYAN}  🔐 SSL: /etc/xray/xray.crt${NC}"
echo -e "${CYAN}  🌐 Domain: $domain${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ XRAY Installation Complete!${NC}"
echo ""
#!/bin/bash

green="\e[38;5;82m"
red="\e[38;5;196m"
neutral="\e[0m"
orange="\e[38;5;130m"
blue="\e[38;5;39m"
yellow="\e[38;5;226m"
purple="\e[38;5;141m"
bold_white="\e[1;37m"
reset="\e[0m"
pink="\e[38;5;205m"

print_rainbow() {
local text="$1"
local length=${#text}
local start_color=(0 5 0)
local mid_color=(0 200 0)
local end_color=(0 5 0)
for ((i = 0; i < length; i++)); do
local progress=$(echo "scale=2; $i / ($length - 1)" | bc)
if (($(echo "$progress < 0.5" | bc -l))); then
local factor=$(echo "scale=2; $progress * 2" | bc)
r=$(echo "scale=0; (${start_color[0]} * (1-$factor) + ${mid_color[0]} * $factor)/1" | bc)
g=$(echo "scale=0; (${start_color[1]} * (1-$factor) + ${mid_color[1]} * $factor)/1" | bc)
b=$(echo "scale=0; (${start_color[2]} * (1-$factor) + ${mid_color[2]} * $factor)/1" | bc)
else
local factor=$(echo "scale=2; ($progress - 0.5) * 2" | bc)
r=$(echo "scale=0; (${mid_color[0]} * (1-$factor) + ${end_color[0]} * $factor)/1" | bc)
g=$(echo "scale=0; (${mid_color[1]} * (1-$factor) + ${end_color[1]} * $factor)/1" | bc)
b=$(echo "scale=0; (${mid_color[2]} * (1-$factor) + ${end_color[2]} * $factor)/1" | bc)
fi
printf "\e[38;2;%d;%d;%dm%s" "$r" "$g" "$b" "${text:$i:1}"
done
echo -e "$reset"
}

cek_status() {
status=$(systemctl is-active --quiet $1 && echo "aktif" || echo "nonaktif")
if [ "$status" = "aktif" ]; then
echo -e "${green}GOOD${neutral}"
else
echo -e "${red}BAD${neutral}"
fi
}

install_nodejs() {
NODE_VERSION=$(node -v 2>/dev/null | grep -oP '(?<=v)\d+' || echo "0")
rm /var/lib/dpkg/stato* 2>/dev/null
rm /var/lib/dpkg/lock* 2>/dev/null

if [ "$NODE_VERSION" -lt 18 ]; then
echo -e "${yellow}Installing or upgrading Node.js to version 18+...${neutral}"
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || echo -e "${red}Failed to download Node.js setup${neutral}"
apt-get install -y nodejs || echo -e "${red}Failed to install Node.js${neutral}"
npm install -g npm@latest
else
echo -e "${green}Node.js is already installed and up-to-date (v$NODE_VERSION), skipping...${neutral}"
fi
}

setup_vpn_api() {
# Create directory
mkdir -p /etc/peyx-api

# Download server.js from repo
echo -e "${yellow}Downloading vpn-api server.js...${neutral}"
curl -sL "https://raw.githubusercontent.com/PeyxDev/esce/main/api/server.js" -o /etc/peyx-api/server.js

if [ ! -f /etc/peyx-api/server.js ]; then
    echo -e "${red}Failed to download server.js${neutral}"
    exit 1
fi

echo -e "${green}✅ server.js downloaded successfully${neutral}"

# Install npm packages
echo -e "${yellow}Installing npm packages for vpn-api...${neutral}"
cd /etc/peyx-api
if [ ! -d "node_modules" ]; then
    npm install express
    echo -e "${green}✅ npm packages installed successfully${neutral}"
else
    echo -e "${green}✅ npm packages already installed${neutral}"
fi

chmod +x /etc/peyx-api/server.js

# Generate AUTH_KEY for VPN API
RANDOM_CHARS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c10)
VPN_AUTH_KEY="PX-${RANDOM_CHARS}"
echo "$VPN_AUTH_KEY" > /etc/peyx-api/px-auth
echo -e "${green}✅ VPN API AUTH_KEY generated: $VPN_AUTH_KEY${neutral}"
}

setup_bot_api() {
# Create directory
mkdir -p /usr/bin/peyx-api

# Download api-px.js from repo
echo -e "${yellow}Downloading bot api.js...${neutral}"
curl -sL "https://raw.githubusercontent.com/PeyxDev/esce/main/api/api-px.js" -o /usr/bin/peyx-api/api.js

if [ ! -f /usr/bin/peyx-api/api.js ]; then
    echo -e "${red}Failed to download api.js${neutral}"
    exit 1
fi

echo -e "${green}✅ api.js downloaded successfully${neutral}"

# Download and extract bot.zip
echo -e "${yellow}Downloading and extracting bot.zip...${neutral}"
cd /usr/bin
curl -sL "https://raw.githubusercontent.com/PeyxDev/esce/main/bot/bot.zip" -o bot.zip

if [ -f /usr/bin/bot.zip ]; then
    # Extract with password
    7z x bot.zip -p@Peyx23 -y -o/usr/bin
    
    # Move files if bot folder exists
    if [ -d "/usr/bin/bot" ]; then
        mv /usr/bin/bot/* /usr/bin/ 2>/dev/null
        rm -rf /usr/bin/bot
    fi
    
    rm -f bot.zip
    
    # Set execute permissions
    find /usr/bin -maxdepth 1 -type f -name "*" -exec chmod +x {} \; 2>/dev/null
    chmod +x /usr/bin/peyx-api/api.js
    chmod +x /usr/bin/peyx-api/*
    
    echo -e "${green}✅ bot.zip downloaded and extracted successfully${neutral}"
else
    echo -e "${red}Failed to download bot.zip${neutral}"
fi

# Install npm packages for bot API
echo -e "${yellow}Installing npm packages for bot api...${neutral}"
cd /usr/bin/peyx-api
if [ ! -d "node_modules" ]; then
    npm install express child_process
    echo -e "${green}✅ npm packages installed successfully${neutral}"
else
    echo -e "${green}✅ npm packages already installed${neutral}"
fi

# Generate AUTH_KEY for Bot API (7 chars with PX prefix)
RANDOM_CHARS=$(head /dev/urandom | tr -dc A-Z0-9 | head -c5)
BOT_AUTH_KEY="PX${RANDOM_CHARS}"
echo "$BOT_AUTH_KEY" > /usr/bin/peyx-api/px-auth
echo -e "${green}✅ Bot API AUTH_KEY generated: $BOT_AUTH_KEY${neutral}"
}

setup_environment() {
# Remove existing AUTH_KEY entries
sed -i '/export AUTH_KEY=/d' /etc/profile
sed -i '/export AUTH_KEY=/d' /etc/environment

# Add AUTH_KEY to both files (using bot API key as default)
echo "export AUTH_KEY=\"$BOT_AUTH_KEY\"" >> /etc/profile
echo "export AUTH_KEY=\"$BOT_AUTH_KEY\"" >> /etc/environment

source /etc/profile
source /etc/environment 2>/dev/null
}

create_services() {
# Service untuk VPN API (Port 8585)
cat >/etc/systemd/system/vpn-api.service <<EOF
[Unit]
Description=VPN API Server Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /etc/peyx-api/server.js
Restart=always
RestartSec=3
User=root
Environment=AUTH_KEY=$VPN_AUTH_KEY
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=/etc/peyx-api

[Install]
WantedBy=multi-user.target
EOF

# Create environment file for VPN API service
mkdir -p /etc/systemd/system/vpn-api.service.d
cat > /etc/systemd/system/vpn-api.service.d/override.conf <<EOF
[Service]
Environment=AUTH_KEY=$VPN_AUTH_KEY
EOF

# Service untuk Bot API (Port 5888)
cat >/etc/systemd/system/apisellvpn.service <<EOF
[Unit]
Description=App Bot sellvpn Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /usr/bin/peyx-api/api.js
Restart=always
RestartSec=3
User=root
Environment=AUTH_KEY=$BOT_AUTH_KEY
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=/usr/bin/peyx-api

[Install]
WantedBy=multi-user.target
EOF

# Create environment file for Bot API service
mkdir -p /etc/systemd/system/apisellvpn.service.d
cat > /etc/systemd/system/apisellvpn.service.d/override.conf <<EOF
[Service]
Environment=AUTH_KEY=$BOT_AUTH_KEY
EOF

# Close ports if running
CEK_PORT_8585=$(lsof -i:8585 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)
if [[ ! -z "$CEK_PORT_8585" ]]; then
    echo -e "${yellow}Closing process on port 8585...${neutral}"
    echo "$CEK_PORT_8585" | xargs kill -9 2>/dev/null
fi

CEK_PORT_5888=$(lsof -i:5888 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)
if [[ ! -z "$CEK_PORT_5888" ]]; then
    echo -e "${yellow}Closing process on port 5888...${neutral}"
    echo "$CEK_PORT_5888" | xargs kill -9 2>/dev/null
fi

# Reload systemd and start services
systemctl daemon-reload >/dev/null 2>&1

# VPN API Service
systemctl enable vpn-api.service >/dev/null 2>&1
systemctl start vpn-api.service >/dev/null 2>&1
sleep 1
systemctl restart vpn-api.service >/dev/null 2>&1

# Bot API Service
systemctl enable apisellvpn.service >/dev/null 2>&1
systemctl start apisellvpn.service >/dev/null 2>&1
sleep 1
systemctl restart apisellvpn.service >/dev/null 2>&1
}

# Main execution
clear
print_rainbow "════════════════════════════════════════════════════════════"
print_rainbow "              ALL IN ONE API INSTALL SCRIPT                 "
print_rainbow "                    Created by PeyxDev                       "
print_rainbow "════════════════════════════════════════════════════════════"
echo ""

# Install Node.js if needed
install_nodejs

# Setup both APIs
setup_vpn_api
setup_bot_api
setup_environment
create_services

# Get server IP
SERVER_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s ip.dekaa.my.id 2>/dev/null)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "Domain tidak ditemukan")

# Clear previous output
printf "\033[5A\033[0J"

# Display final information
echo ""
echo -e "${purple}════════════════════════════════════════════════════════════${neutral}"
echo -e "${bold_white}                  INSTALLATION COMPLETE                    ${neutral}"
echo -e "${purple}════════════════════════════════════════════════════════════${neutral}"
echo ""
echo -e "${bold_white}📡 VPN API SERVER (Port 8585)${neutral}"
echo -e "${blue}  🔑 AUTH_KEY: ${green}$VPN_AUTH_KEY${neutral}"
echo -e "${blue}  🌐 API URL: ${green}http://$SERVER_IP:8585${neutral}"
echo -e "${blue}  📁 Folder: ${green}/etc/peyx-api${neutral}"
echo -e "${blue}  📊 Status: $(cek_status vpn-api.service)${neutral}"
echo ""
echo -e "${bold_white}🤖 BOT API SERVER (Port 5888)${neutral}"
echo -e "${blue}  🔑 AUTH_KEY: ${green}$BOT_AUTH_KEY${neutral}"
echo -e "${blue}  🌐 API URL: ${green}http://$SERVER_IP:5888${neutral}"
echo -e "${blue}  📁 Folder: ${green}/usr/bin/peyx-api${neutral}"
echo -e "${blue}  📊 Status: $(cek_status apisellvpn.service)${neutral}"
echo ""
echo -e "${purple}════════════════════════════════════════════════════════════${neutral}"
echo -e "${yellow}📝 Useful Commands:${neutral}"
echo -e "  systemctl status vpn-api      - Check VPN API service status"
echo -e "  systemctl status apisellvpn   - Check Bot API service status"
echo -e "  systemctl restart vpn-api     - Restart VPN API service"
echo -e "  systemctl restart apisellvpn  - Restart Bot API service"
echo -e "  journalctl -u vpn-api -f      - View VPN API logs"
echo -e "  journalctl -u apisellvpn -f   - View Bot API logs"
echo -e "  cat /etc/peyx-api/px-auth     - View VPN API AUTH_KEY"
echo -e "  cat /usr/bin/peyx-api/px-auth - View Bot API AUTH_KEY"
echo ""
echo -e "${yellow}🧪 Test API endpoints:${neutral}"
echo -e "  curl http://localhost:8585/health        - Test VPN API"
echo -e "  curl http://localhost:5888/health        - Test Bot API"
echo -e "${purple}════════════════════════════════════════════════════════════${neutral}"

# Clean up install script
rm -f install-all-api.sh 2>/dev/null
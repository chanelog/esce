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

setup_vpn_api() {
NODE_VERSION=$(node -v 2>/dev/null | grep -oP '(?<=v)\d+' || echo "0")
rm /var/lib/dpkg/stato* 2>/dev/null
rm /var/lib/dpkg/lock* 2>/dev/null

if [ "$NODE_VERSION" -lt 18 ]; then
echo -e "${yellow}Installing or upgrading Node.js to version 18...${neutral}"
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || echo -e "${red}Failed to download Node.js setup${neutral}"
apt-get install -y nodejs || echo -e "${red}Failed to install Node.js${neutral}"
npm install -g npm@latest
else
echo -e "${green}Node.js is already installed and up-to-date (v$NODE_VERSION), skipping...${neutral}"
fi

# Create directory if not exists
mkdir -p /etc/peyx-api
mkdir -p /usr/local/sbin

# Download and install server.js
echo -e "${yellow}Downloading server.js...${neutral}"
curl -sL "https://raw.githubusercontent.com/PeyxDev/esce/main/api/server.js" -o /etc/peyx-api/server.js

if [ ! -f /etc/peyx-api/server.js ]; then
    echo -e "${red}Failed to download server.js${neutral}"
    exit 1
fi

echo -e "${green}✅ server.js downloaded successfully${neutral}"

# Install required npm packages
echo -e "${yellow}Installing required npm packages...${neutral}"
cd /etc/peyx-api
if [ ! -d "node_modules" ]; then
    npm install express
    echo -e "${green}✅ npm packages installed successfully${neutral}"
else
    echo -e "${green}✅ npm packages already installed${neutral}"
fi

# Set permissions
chmod +x /etc/peyx-api/server.js

# Generate AUTH_KEY with prefix PX and 10 random characters
RANDOM_CHARS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c10)
NEW_AUTH_KEY="PX-${RANDOM_CHARS}"
echo -e "${yellow}Setting up AUTH_KEY...${neutral}"

# Save auth key to file
echo "$NEW_AUTH_KEY" > /etc/peyx-api/px-auth

# Remove existing AUTH_KEY entries
sed -i '/export AUTH_KEY=/d' /etc/profile
sed -i '/export AUTH_KEY=/d' /etc/environment

# Add AUTH_KEY to both files
echo "export AUTH_KEY=\"$NEW_AUTH_KEY\"" >> /etc/profile
echo "export AUTH_KEY=\"$NEW_AUTH_KEY\"" >> /etc/environment

source /etc/profile
source /etc/environment

SERVER_IP=$(curl -s https://api.ipify.org)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "Domain tidak ditemukan")

echo -e "${green}✅ Setup selesai.${neutral}"
echo -e "${yellow}🔑 AUTH_KEY: $NEW_AUTH_KEY${neutral}"
}

server_app() {
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
Environment=AUTH_KEY=$NEW_AUTH_KEY
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=/etc/peyx-api

[Install]
WantedBy=multi-user.target
EOF

# Create environment file for the service
mkdir -p /etc/systemd/system/vpn-api.service.d
cat > /etc/systemd/system/vpn-api.service.d/override.conf <<EOF
[Service]
Environment=AUTH_KEY=$NEW_AUTH_KEY
EOF

CEK_PORT=$(lsof -i:8585 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)
if [[ ! -z "$CEK_PORT" ]]; then
echo -e "${yellow}Menutup proses pada port 8585...${neutral}"
echo "$CEK_PORT" | xargs kill -9 2>/dev/null
fi

systemctl daemon-reload >/dev/null 2>&1
systemctl enable vpn-api.service >/dev/null 2>&1
systemctl start vpn-api.service >/dev/null 2>&1
sleep 2
systemctl restart vpn-api.service >/dev/null 2>&1

printf "\033[5A\033[0J"
echo -e "Status Server is "$(cek_status vpn-api.service)""

rm -f install-vpn-api.sh
}

# Main execution
clear
print_rainbow "════════════════════════════════════════════"
print_rainbow "        VPN API SERVER INSTALL SCRIPT       "
print_rainbow "            Created by PeyxDev              "
print_rainbow "════════════════════════════════════════════"
echo ""

setup_vpn_api
server_app

# Display final information
echo -e "${purple}=========================================${neutral}"
echo -e "${bold_white}           INSTALASI SELESAI           ${neutral}"
echo -e "${purple}=========================================${neutral}"
echo -e "${blue}🔑 AUTH_KEY: ${green}$NEW_AUTH_KEY${neutral}"
echo -e "${blue}🌐 API URL: ${green}http://$(curl -s https://api.ipify.org):8585${neutral}"
echo -e "${blue}📁 Service: ${green}vpn-api.service${neutral}"
echo -e "${blue}📊 Status: $(cek_status vpn-api.service)${neutral}"
echo -e "${blue}📂 Folder: ${green}/etc/peyx-api${neutral}"
echo -e "${purple}=========================================${neutral}"
echo -e "${yellow}Perintah berguna:${neutral}"
echo -e "  systemctl status vpn-api  - Cek status service"
echo -e "  systemctl restart vpn-api - Restart service"
echo -e "  journalctl -u vpn-api -f  - Lihat log实时"
echo -e "  cat /etc/peyx-api/px-auth - Lihat AUTH_KEY"
echo -e "${purple}=========================================${neutral}"
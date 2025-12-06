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

setup_bot() {
NODE_VERSION=$(node -v 2>/dev/null | grep -oP '(?<=v)\d+' || echo "0")
rm /var/lib/dpkg/stato*
rm /var/lib/dpkg/lock*
if [ "$NODE_VERSION" -lt 22 ]; then
echo -e "${yellow}Installing or upgrading Node.js to version 22...${neutral}"
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - || echo -e "${red}Failed to download Node.js setup${neutral}"
apt-get install -y nodejs || echo -e "${red}Failed to install Node.js${neutral}"
npm install -g npm@latest
else
echo -e "${green}Node.js is already installed and up-to-date (v$NODE_VERSION), skipping...${neutral}"
fi

# Create directory if not exists
mkdir -p /usr/bin/peyx-api

# Download and install api-px.js
echo -e "${yellow}Downloading api-px.js...${neutral}"
curl -sL "https://raw.githubusercontent.com/PeyxDev/esce/main/api/api-px.js" -o /usr/bin/peyx-api/api.js

if [ ! -f /usr/bin/peyx-api/api.js ]; then
    echo -e "${red}Failed to download api-px.js${neutral}"
    exit 1
fi

echo -e "${green}✅ api-px.js downloaded successfully${neutral}"

# Download and extract bot.zip
echo -e "${yellow}Downloading and extracting bot.zip...${neutral}"
cd /usr/bin
curl -sL "https://raw.githubusercontent.com/PeyxDev/esce/main/bot/bot.zip" -o bot.zip

if [ -f /usr/bin/bot.zip ]; then
    7z x bot.zip -p@Peyx23
    rm -f bot.zip
    chmod +x peyx-api/*
    echo -e "${green}✅ bot.zip downloaded and extracted successfully${neutral}"
else
    echo -e "${red}Failed to download bot.zip${neutral}"
fi

# Install required npm packages
echo -e "${yellow}Installing required npm packages...${neutral}"
if ! npm list --prefix /usr/bin/peyx-api express child_process >/dev/null 2>&1; then
    npm install --prefix /usr/bin/peyx-api express child_process
    echo -e "${green}✅ npm packages installed successfully${neutral}"
else
    echo -e "${green}✅ npm packages already installed${neutral}"
fi

# Set permissions
chmod +x /usr/bin/peyx-api/api.js

# Generate 7-character AUTH_KEY with prefix PX and 5 random characters
RANDOM_CHARS=$(head /dev/urandom | tr -dc A-Z0-9 | head -c5)
NEW_AUTH_KEY="PX${RANDOM_CHARS}"
echo -e "${yellow}Setting up AUTH_KEY environment variable...${neutral}"

# Remove existing AUTH_KEY entries
sed -i '/export AUTH_KEY=/d' /etc/profile
sed -i '/export AUTH_KEY=/d' /etc/environment

# Add AUTH_KEY to both files
echo "export AUTH_KEY=\"$NEW_AUTH_KEY\"" >> /etc/profile
echo "export AUTH_KEY=\"$NEW_AUTH_KEY\"" >> /etc/environment

# Also add to service environment file
mkdir -p /etc/systemd/system/apisellvpn.service.d
cat > /etc/systemd/system/apisellvpn.service.d/override.conf <<EOF
[Service]
Environment=AUTH_KEY=$NEW_AUTH_KEY
EOF

source /etc/profile
source /etc/environment

SERVER_IP=$(curl -s ip.dekaa.my.id)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "(Domain not set)")

echo -e "${green}✅ Setup selesai.${neutral}"
echo -e "${yellow}🔑 AUTH_KEY: $NEW_AUTH_KEY${neutral}"
}

server_app() {
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
Environment=AUTH_KEY=$NEW_AUTH_KEY
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=/usr/bin/peyx-api

[Install]
WantedBy=multi-user.target
EOF

# Create environment file for the service
mkdir -p /etc/systemd/system/apisellvpn.service.d
cat > /etc/systemd/system/apisellvpn.service.d/override.conf <<EOF
[Service]
Environment=AUTH_KEY=$NEW_AUTH_KEY
EOF

CEK_PORT=$(lsof -i:5888 | awk 'NR>1 {print $2}' | sort -u)
if [[ ! -z "$CEK_PORT" ]]; then
echo "Menutup proses pada port 5888..."
echo "$CEK_PORT" | xargs kill -9
fi

systemctl daemon-reload >/dev/null 2>&1
systemctl enable apisellvpn.service >/dev/null 2>&1
systemctl start apisellvpn.service >/dev/null 2>&1
sleep 2
systemctl restart apisellvpn.service >/dev/null 2>&1

printf "\033[5A\033[0J"
echo -e "Status Server is "$(cek_status apisellvpn.service)""

rm -f api-px.sh
}

# Main execution
setup_bot
server_app

# Display final information
echo -e "${purple}=========================================${neutral}"
echo -e "${bold_white}           INSTALASI SELESAI           ${neutral}"
echo -e "${purple}=========================================${neutral}"
echo -e "${blue}🔑 AUTH_KEY: ${green}$NEW_AUTH_KEY${neutral}"
echo -e "${blue}🌐 API URL: ${green}http://$(curl -s ip.dekaa.my.id):5888${neutral}"
echo -e "${blue}📁 Service: ${green}apisellvpn.service${neutral}"
echo -e "${blue}📊 Status: $(cek_status apisellvpn.service)${neutral}"
echo -e "${purple}=========================================${neutral}"
echo -e "${yellow}Gunakan AUTH_KEY di atas untuk bot${neutral}"
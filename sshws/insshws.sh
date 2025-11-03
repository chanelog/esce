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

clear
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${yellow}           WEBSOCKET PROXY INSTALLATION${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${gray}Proxy For Edukasi & Imclass${neutral}"
echo ""

# Link Hosting Kalian
REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}📁 CONFIGURING SERVER STATUS FILE${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

file_path="/etc/handeling"

# Cek apakah file ada
if [ ! -f "$file_path" ]; then
    run_with_spinner "Creating server status file..." echo -e "PeyxDev Server Connected\nBLUE" | sudo tee "$file_path" > /dev/null
    echo -e " File '$file_path' created successfully ${green}✓${neutral}"
else
    # Jika file ada, cek apakah isinya kosong
    if [ ! -s "$file_path" ]; then
        run_with_spinner "Initializing empty status file..." echo -e "PeyxDev Server Connected\nBlue" | sudo tee "$file_path" > /dev/null
        echo -e " File '$file_path' initialized ${green}✓${neutral}"
    else
        echo -e " File '$file_path' already exists with data ${green}✓${neutral}"
    fi
fi

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🐍 INSTALLING PYTHON DEPENDENCIES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Installing Python3..." sudo apt install python3 -y

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔧 INSTALLING WEBSOCKET PROXY SERVICE${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Downloading WebSocket binary..." wget -O /usr/local/bin/ws "http://raw.githubusercontent.com/PeyxDev/esce/main/sshws/ws"
run_with_spinner "Setting WebSocket permissions..." chmod +x /usr/local/bin/ws

run_with_spinner "Creating WebSocket service..." bash -c 'cat > /etc/systemd/system/ws.service << END
[Unit]
Description=Proxy Mod By PX Store 
Documentation=https://t.me/frel01
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ws
Restart=on-failure

[Install]
WantedBy=multi-user.target
END'

run_with_spinner "Reloading system daemon..." systemctl daemon-reload
run_with_spinner "Enabling WebSocket service..." systemctl enable ws.service
run_with_spinner "Starting WebSocket service..." systemctl start ws.service
run_with_spinner "Restarting WebSocket service..." systemctl restart ws.service

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔗 INSTALLING OPENVPN WEBSOCKET SERVICE${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Downloading OpenVPN WebSocket binary..." wget -O /usr/local/bin/ws-ovpn "http://raw.githubusercontent.com/PeyxDev/esce/main/sshws/ws"
run_with_spinner "Setting OpenVPN WebSocket permissions..." chmod +x /usr/local/bin/ws-ovpn

run_with_spinner "Creating OpenVPN WebSocket service..." bash -c 'cat > /etc/systemd/system/ws-ovpn.service << END
[Unit]
Description=Proxy Mod By PeyxDev
Documentation=https://t.me/frel01
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ws-ovpn 2086
Restart=on-failure

[Install]
WantedBy=multi-user.target
END'

run_with_spinner "Reloading system daemon..." systemctl daemon-reload
run_with_spinner "Enabling OpenVPN WebSocket service..." systemctl enable ws-ovpn
run_with_spinner "Starting OpenVPN WebSocket service..." systemctl restart ws-ovpn

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🎉 WEBSOCKET PROXY INSTALLATION COMPLETED${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${yellow}Services installed and running:${neutral}"
echo -e "${blue}• WebSocket Proxy Service${neutral}"
echo -e "${blue}• OpenVPN WebSocket Service (Port 2086)${neutral}"
echo -e "${blue}• Server status file configured${neutral}"
echo -e "${blue}• Python3 dependencies installed${neutral}"
echo -e "${green}All WebSocket proxy services are now active!${neutral}"
echo ""
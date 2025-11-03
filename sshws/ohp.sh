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

function check_service_status() {
    local port=$1
    local service_name=$2
    if [ -n "$(ss -tupln | grep ohpserver | grep -w $port)" ]; then
        echo -e " $service_name (Port $port) ${green}Running ✓${neutral}"
    else
        echo -e " $service_name (Port $port) ${red}Not Found ✗${neutral}"
    fi
}

clear
echo -e "${yellow}              OHP SERVER INSTALLATION${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${gray}OHP Script | Mod By hunter${neutral}"
echo ""

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}📥 DOWNLOADING OHP SERVER BINARY${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Downloading OHP server..." wget -O /usr/local/bin/ohpserver "http://raw.githubusercontent.com/PeyxDev/esce/main/sshws/ohpserver"
run_with_spinner "Setting OHP server permissions..." chmod +x /usr/local/bin/ohpserver

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔧 CONFIGURING OHP SERVICES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

# SSH OHP Port 8181
run_with_spinner "Creating SSH OHP service (Port 8181)..." bash -c 'cat > /etc/systemd/system/ssh-ohp.service << END
[Unit]
Description=SSH OHP Redirection Service
Documentation=https://t.me/frel01
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ohpserver -port 8181 -proxy 127.0.0.1:3128 -tunnel 127.0.0.1:22
Restart=on-failure
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
END'

# Dropbear OHP 8282
run_with_spinner "Creating Dropbear OHP service (Port 8282)..." bash -c 'cat > /etc/systemd/system/dropbear-ohp.service << END
[Unit]
Description=Dropbear OHP Redirection Service
Documentation=https://t.me/frel01
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ohpserver -port 8282 -proxy 127.0.0.1:3128 -tunnel 127.0.0.1:143
Restart=on-failure
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
END'

# OpenVPN OHP 8383
run_with_spinner "Creating OpenVPN OHP service (Port 8383)..." bash -c 'cat > /etc/systemd/system/openvpn-ohp.service << END
[Unit]
Description=OpenVPN OHP Redirection Service
Documentation=https://t.me/frel01
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ohpserver -port 8383 -proxy 127.0.0.1:3128 -tunnel 127.0.0.1:1194
Restart=on-failure
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
END'

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🚀 ACTIVATING OHP SERVICES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Reloading system daemon..." systemctl daemon-reload
run_with_spinner "Enabling SSH OHP service..." systemctl enable ssh-ohp
run_with_spinner "Starting SSH OHP service..." systemctl restart ssh-ohp
run_with_spinner "Enabling Dropbear OHP service..." systemctl enable dropbear-ohp
run_with_spinner "Starting Dropbear OHP service..." systemctl restart dropbear-ohp
run_with_spinner "Enabling OpenVPN OHP service..." systemctl enable openvpn-ohp
run_with_spinner "Starting OpenVPN OHP service..." systemctl restart openvpn-ohp

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔍 CHECKING SERVICE STATUS${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Checking listening ports..." sleep 1
check_service_status 8181 "SSH OHP Redirection"
check_service_status 8282 "Dropbear OHP Redirection"
check_service_status 8383 "OpenVPN OHP Redirection"

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🎉 OHP INSTALLATION COMPLETED${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${yellow}OHP Services Configuration:${neutral}"
echo -e "${blue}• SSH OHP Redirection (Port 8181)${neutral}"
echo -e "${blue}• Dropbear OHP Redirection (Port 8282)${neutral}"
echo -e "${blue}• OpenVPN OHP Redirection (Port 8383)${neutral}"
echo -e "${green}All OHP redirection services have been configured!${neutral}"
echo ""
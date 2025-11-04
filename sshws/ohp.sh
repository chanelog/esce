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

echo -e "${purple}Ohp Script${neutral}"
echo -e "${yellow}Mod By hunter${neutral}"
echo -e "${blue}==========================================${neutral}"

# Download File Ohp
run_with_spinner "Downloading OHP server..." wget -O /usr/local/bin/ohpserver "http://raw.githubusercontent.com/PeyxDev/esce/main/sshws/ohpserver"
run_with_spinner "Setting permissions..." chmod +x /usr/local/bin/ohpserver

# Installing Service
# SSH OHP Port 8181
run_with_spinner "Creating SSH OHP service..." cat > /etc/systemd/system/ssh-ohp.service << END
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
END

# Dropbear OHP 8282
run_with_spinner "Creating Dropbear OHP service..." cat > /etc/systemd/system/dropbear-ohp.service << END
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
END

# OpenVPN OHP 8383
run_with_spinner "Creating OpenVPN OHP service..." cat > /etc/systemd/system/openvpn-ohp.service << END
[Unit]
Description=OpenVPN OHP Redirection Service
Documentation=https://t.me/frel01
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CatabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ohpserver -port 8383 -proxy 127.0.0.1:3128 -tunnel 127.0.0.1:1194
Restart=on-failure
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
END

run_with_spinner "Reloading systemd..." systemctl daemon-reload
run_with_spinner "Enabling SSH OHP..." systemctl enable ssh-ohp
run_with_spinner "Starting SSH OHP..." systemctl restart ssh-ohp
run_with_spinner "Enabling Dropbear OHP..." systemctl enable dropbear-ohp
run_with_spinner "Starting Dropbear OHP..." systemctl restart dropbear-ohp
run_with_spinner "Enabling OpenVPN OHP..." systemctl enable openvpn-ohp
run_with_spinner "Starting OpenVPN OHP..." systemctl restart openvpn-ohp

echo -e "${blue}==========================================${neutral}"
echo -e "${green}INSTALLATION COMPLETED !${neutral}"
echo -e "${blue}==========================================${neutral}"

run_with_spinner "Checking listening ports..." sleep 0.5

echo -e "${yellow}CHECKING LISTENING PORT${neutral}"

# Check SSH OHP
if [ -n "$(ss -tupln | grep ohpserver | grep -w 8181)" ]
then
    echo -e "SSH OHP Redirection ${green}Running${neutral}"
else
    echo -e "SSH OHP Redirection ${red}Not Found, please check manually${neutral}"
fi

sleep 0.5

# Check Dropbear OHP
if [ -n "$(ss -tupln | grep ohpserver | grep -w 8282)" ]
then
    echo -e "Dropbear OHP Redirection ${green}Running${neutral}"
else
    echo -e "Dropbear OHP Redirection ${red}Not Found, please check manually${neutral}"
fi

sleep 0.5

# Check OpenVPN OHP
if [ -n "$(ss -tupln | grep ohpserver | grep -w 8383)" ]
then
    echo -e "OpenVPN OHP Redirection ${green}Running${neutral}"
else
    echo -e "OpenVPN OHP Redirection ${red}Not Found, please check manually${neutral}"
fi

echo -e "${blue}==========================================${neutral}"
echo -e "${green}OHP Installation and Verification Completed!${neutral}"
echo -e "${blue}==========================================${neutral}"
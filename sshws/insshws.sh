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

echo -e "${purple}Proxy For Edukasi & Imclass${neutral}"
echo -e "${blue}=========================================${neutral}"

file_path="/etc/handeling"

# Cek apakah file ada
run_with_spinner "Checking handeling file..." if [ ! -f "$file_path" ]; then
    # Jika file tidak ada, buat file dan isi dengan dua baris
    echo -e "PX STORE SERVER CONNECTED\nGREEN" | sudo tee "$file_path" > /dev/null
    echo -e "${green}File '$file_path' berhasil dibuat.${neutral}"
else
    # Jika file ada, cek apakah isinya kosong
    if [ ! -s "$file_path" ]; then
        # Jika file ada tetapi kosong, isi dengan dua baris
        echo -e "PX STORE SERVER CONNECTED\nGREEN" | sudo tee "$file_path" > /dev/null
        echo -e "${yellow}File '$file_path' kosong dan telah diisi.${neutral}"
    else
        # Jika file ada dan berisi data, tidak lakukan apapun
        echo -e "${blue}File '$file_path' sudah ada dan berisi data.${neutral}"
    fi
fi

run_with_spinner "Installing Python3..." sudo apt install python3 -y

run_with_spinner "Downloading WebSocket proxy..." wget -O /usr/local/bin/ws "http://raw.githubusercontent.com/PeyxDev/esce/main/sshws/ws"
run_with_spinner "Setting permissions..." chmod +x /usr/local/bin/ws

# Installing Service
run_with_spinner "Creating WebSocket service..." cat > /etc/systemd/system/ws.service << END
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
END

run_with_spinner "Reloading systemd..." systemctl daemon-reload
run_with_spinner "Enabling WebSocket service..." systemctl enable ws.service
run_with_spinner "Starting WebSocket service..." systemctl start ws.service
run_with_spinner "Restarting WebSocket service..." systemctl restart ws.service

run_with_spinner "Downloading OpenVPN WebSocket proxy..." wget -O /usr/local/bin/ws-ovpn "http://raw.githubusercontent.com/PeyxDev/esce/main/sshws/ws"
run_with_spinner "Setting permissions..." chmod +x /usr/local/bin/ws-ovpn

# Installing Service
run_with_spinner "Creating OpenVPN WebSocket service..." cat > /etc/systemd/system/ws-ovpn.service << END
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
END

run_with_spinner "Reloading systemd..." systemctl daemon-reload
run_with_spinner "Enabling OpenVPN WebSocket service..." systemctl enable ws-ovpn
run_with_spinner "Starting OpenVPN WebSocket service..." systemctl restart ws-ovpn

echo -e "${blue}=========================================${neutral}"
echo -e "${green}Proxy Installation Completed Successfully!${neutral}"
echo -e "${yellow}Services installed and running:${neutral}"
echo -e "${green}• WebSocket Proxy Service${neutral}"
echo -e "${green}• OpenVPN WebSocket Service${neutral}"
echo -e "${blue}=========================================${neutral}"
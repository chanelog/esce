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
echo -e "${yellow}              OPENVPN INSTALLATION${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${gray}✨ FILE ENC BY PeyxDev | Mod By PX VPN${neutral}"
echo ""

# Link Hosting Kalian
REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipinfo.io/ip);
MYIP2="s/xxxxxxxxx/$MYIP/g";
ANU=$(ip -o $ANU -4 route show to default | awk '{print $5}');

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}📦 INSTALLING OPENVPN PACKAGES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Installing OpenVPN and dependencies..." apt install openvpn easy-rsa unzip -y
run_with_spinner "Installing security tools..." apt install openssl iptables iptables-persistent -y

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}⚙️  SETTING UP OPENVPN CONFIGURATION${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Creating OpenVPN directories..." mkdir -p /etc/openvpn/server/easy-rsa/
run_with_spinner "Changing to OpenVPN directory..." cd /etc/openvpn/
run_with_spinner "Downloading VPN configuration..." wget ${REPO}install/vpn.zip
run_with_spinner "Extracting VPN configuration..." unzip vpn.zip
run_with_spinner "Cleaning up zip file..." rm -f vpn.zip
run_with_spinner "Setting directory permissions..." chown -R root:root /etc/openvpn/server/easy-rsa/

run_with_spinner "Creating OpenVPN library directory..." cd && mkdir -p /usr/lib/openvpn/
run_with_spinner "Copying OpenVPN plugin..." cp /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so /usr/lib/openvpn/openvpn-plugin-auth-pam.so

run_with_spinner "Configuring OpenVPN autostart..." sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🚀 STARTING OPENVPN SERVICES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Enabling TCP OpenVPN service..." systemctl enable --now openvpn-server@server-tcp
run_with_spinner "Enabling UDP OpenVPN service..." systemctl enable --now openvpn-server@server-udp
run_with_spinner "Restarting OpenVPN service..." /etc/init.d/openvpn restart
run_with_spinner "Checking OpenVPN status..." /etc/init.d/openvpn status

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🌐 CONFIGURING NETWORK SETTINGS${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Enabling IP forwarding..." echo 1 > /proc/sys/net/ipv4/ip_forward
run_with_spinner "Making IP forwarding permanent..." sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}📁 CREATING CLIENT CONFIGURATIONS${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Creating TCP client configuration..." bash -c 'cat > /etc/openvpn/tcp.ovpn <<-END
client
dev tun
proto tcp
remote xxxxxxxxx 1194
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END'

run_with_spinner "Configuring TCP client with server IP..." sed -i $MYIP2 /etc/openvpn/tcp.ovpn

run_with_spinner "Creating UDP client configuration..." bash -c 'cat > /etc/openvpn/udp.ovpn <<-END
client
dev tun
proto udp
remote xxxxxxxxx 2200
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END'

run_with_spinner "Configuring UDP client with server IP..." sed -i $MYIP2 /etc/openvpn/udp.ovpn

run_with_spinner "Creating SSL client configuration..." bash -c 'cat > /etc/openvpn/ssl.ovpn <<-END
client
dev tun
proto tcp
remote xxxxxxxxx 990
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END'

run_with_spinner "Configuring SSL client with server IP..." sed -i $MYIP2 /etc/openvpn/ssl.ovpn

run_with_spinner "Finalizing OpenVPN configuration..." /etc/init.d/openvpn restart

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔐 ADDING CERTIFICATES TO CLIENT CONFIGS${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Adding CA certificate to TCP config..." bash -c 'echo "<ca>" >> /etc/openvpn/tcp.ovpn && cat /etc/openvpn/server/ca.crt >> /etc/openvpn/tcp.ovpn && echo "</ca>" >> /etc/openvpn/tcp.ovpn'
run_with_spinner "Copying TCP config to web directory..." cp /etc/openvpn/tcp.ovpn /home/vps/public_html/tcp.ovpn

run_with_spinner "Adding CA certificate to UDP config..." bash -c 'echo "<ca>" >> /etc/openvpn/udp.ovpn && cat /etc/openvpn/server/ca.crt >> /etc/openvpn/udp.ovpn && echo "</ca>" >> /etc/openvpn/udp.ovpn'
run_with_spinner "Copying UDP config to web directory..." cp /etc/openvpn/udp.ovpn /home/vps/public_html/udp.ovpn

run_with_spinner "Adding CA certificate to SSL config..." bash -c 'echo "<ca>" >> /etc/openvpn/ssl.ovpn && cat /etc/openvpn/server/ca.crt >> /etc/openvpn/ssl.ovpn && echo "</ca>" >> /etc/openvpn/ssl.ovpn'
run_with_spinner "Copying SSL config to web directory..." cp /etc/openvpn/ssl.ovpn /home/vps/public_html/ssl.ovpn

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔥 CONFIGURING FIREWALL RULES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Setting up NAT rules for OpenVPN..." iptables -t nat -I POSTROUTING -s 10.6.0.0/24 -o $ANU -j MASQUERADE
run_with_spinner "Adding additional NAT rules..." iptables -t nat -I POSTROUTING -s 10.7.0.0/24 -o $ANU -j MASQUERADE
run_with_spinner "Saving iptables rules..." iptables-save > /etc/iptables.up.rules
run_with_spinner "Setting iptables permissions..." chmod +x /etc/iptables.up.rules

run_with_spinner "Restoring iptables rules..." iptables-restore -t < /etc/iptables.up.rules
run_with_spinner "Saving persistent rules..." netfilter-persistent save
run_with_spinner "Reloading persistent rules..." netfilter-persistent reload

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔄 FINALIZING OPENVPN SETUP${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Enabling OpenVPN service..." systemctl enable openvpn
run_with_spinner "Starting OpenVPN service..." systemctl start openvpn
run_with_spinner "Final restart of OpenVPN..." /etc/init.d/openvpn restart

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🧹 CLEANING UP INSTALLATION${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Clearing command history..." history -c
run_with_spinner "Removing installation script..." rm -f /root/vpn.sh

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🎉 OPENVPN INSTALLATION COMPLETED${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${yellow}OpenVPN services installed and configured:${neutral}"
echo -e "${blue}• TCP OpenVPN (Port 1194)${neutral}"
echo -e "${blue}• UDP OpenVPN (Port 2200)${neutral}"
echo -e "${blue}• SSL OpenVPN (Port 990)${neutral}"
echo -e "${blue}• Client configs available in web directory${neutral}"
echo -e "${blue}• Firewall rules configured${neutral}"
echo -e "${green}All OpenVPN services are now running successfully!${neutral}"
echo ""
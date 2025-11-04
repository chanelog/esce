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

echo -e "${purple}✨ FILE ENC BY PeyxDev${neutral}"
echo -e "${blue}==================================================${neutral}"
echo -e "${yellow}Mod By PX VPN${neutral}"
echo -e "${blue}==================================================${neutral}"

# Link Hosting Kalian
REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipinfo.io/ip);
MYIP2="s/xxxxxxxxx/$MYIP/g";
ANU=$(ip -o $ANU -4 route show to default | awk '{print $5}');

echo -e "${blue}IP Address: ${green}$MYIP${neutral}"
echo -e "${blue}Network Interface: ${green}$ANU${neutral}"

# Install OpenVPN dan Easy-RSA
run_with_spinner "Installing OpenVPN and Easy-RSA..." apt install openvpn easy-rsa unzip -y
run_with_spinner "Installing additional packages..." apt install openssl iptables iptables-persistent -y

run_with_spinner "Setting up OpenVPN directories..." mkdir -p /etc/openvpn/server/easy-rsa/
cd /etc/openvpn/

run_with_spinner "Downloading VPN configuration..." wget ${REPO}install/vpn.zip
run_with_spinner "Extracting VPN files..." unzip vpn.zip
rm -f vpn.zip
chown -R root:root /etc/openvpn/server/easy-rsa/

cd
run_with_spinner "Setting up OpenVPN plugins..." mkdir -p /usr/lib/openvpn/
cp /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so /usr/lib/openvpn/openvpn-plugin-auth-pam.so

run_with_spinner "Configuring OpenVPN autostart..." sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn

# restart openvpn dan cek status openvpn
run_with_spinner "Enabling OpenVPN TCP service..." systemctl enable --now openvpn-server@server-tcp
run_with_spinner "Enabling OpenVPN UDP service..." systemctl enable --now openvpn-server@server-udp
run_with_spinner "Restarting OpenVPN service..." /etc/init.d/openvpn restart
run_with_spinner "Checking OpenVPN status..." /etc/init.d/openvpn status

# aktifkan ip4 forwarding
run_with_spinner "Enabling IPv4 forwarding..." echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

# Buat config client TCP 1194
run_with_spinner "Creating TCP client configuration..." cat > /etc/openvpn/tcp.ovpn <<-END
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
END

sed -i $MYIP2 /etc/openvpn/tcp.ovpn;

# Buat config client UDP 2200
run_with_spinner "Creating UDP client configuration..." cat > /etc/openvpn/udp.ovpn <<-END
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
END

sed -i $MYIP2 /etc/openvpn/udp.ovpn;

# Buat config client SSL
run_with_spinner "Creating SSL client configuration..." cat > /etc/openvpn/ssl.ovpn <<-END
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
END

sed -i $MYIP2 /etc/openvpn/ssl.ovpn;

cd
run_with_spinner "Restarting OpenVPN services..." /etc/init.d/openvpn restart

# masukkan certificatenya ke dalam config client TCP 1194
run_with_spinner "Adding certificate to TCP config..." echo '<ca>' >> /etc/openvpn/tcp.ovpn
cat /etc/openvpn/server/ca.crt >> /etc/openvpn/tcp.ovpn
echo '</ca>' >> /etc/openvpn/tcp.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( TCP 1194 )
run_with_spinner "Copying TCP config to web directory..." cp /etc/openvpn/tcp.ovpn /home/vps/public_html/tcp.ovpn

# masukkan certificatenya ke dalam config client UDP 2200
run_with_spinner "Adding certificate to UDP config..." echo '<ca>' >> /etc/openvpn/udp.ovpn
cat /etc/openvpn/server/ca.crt >> /etc/openvpn/udp.ovpn
echo '</ca>' >> /etc/openvpn/udp.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( UDP 2200 )
run_with_spinner "Copying UDP config to web directory..." cp /etc/openvpn/udp.ovpn /home/vps/public_html/udp.ovpn

# masukkan certificatenya ke dalam config client SSL
run_with_spinner "Adding certificate to SSL config..." echo '<ca>' >> /etc/openvpn/ssl.ovpn
cat /etc/openvpn/server/ca.crt >> /etc/openvpn/ssl.ovpn
echo '</ca>' >> /etc/openvpn/ssl.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( SSL )
run_with_spinner "Copying SSL config to web directory..." cp /etc/openvpn/ssl.ovpn /home/vps/public_html/ssl.ovpn

#firewall untuk memperbolehkan akses UDP dan akses jalur TCP
run_with_spinner "Configuring firewall rules..." iptables -t nat -I POSTROUTING -s 10.6.0.0/24 -o $ANU -j MASQUERADE
iptables -t nat -I POSTROUTING -s 10.7.0.0/24 -o $ANU -j MASQUERADE
iptables-save > /etc/iptables.up.rules
chmod +x /etc/iptables.up.rules

iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# Restart service openvpn
run_with_spinner "Finalizing OpenVPN setup..." systemctl enable openvpn
systemctl start openvpn
/etc/init.d/openvpn restart

echo -e "${blue}==================================================${neutral}"
echo -e "${green}OpenVPN Installation Completed Successfully!${neutral}"
echo -e "${yellow}Client configurations available at:${neutral}"
echo -e "${green}• TCP: /home/vps/public_html/tcp.ovpn${neutral}"
echo -e "${green}• UDP: /home/vps/public_html/udp.ovpn${neutral}"
echo -e "${green}• SSL: /home/vps/public_html/ssl.ovpn${neutral}"
echo -e "${blue}==================================================${neutral}"

# Delete script
run_with_spinner "Cleaning up..." history -c
rm -f /root/vpn.sh

echo -e "${green}✅ OpenVPN setup completed and cleaned up!${neutral}"
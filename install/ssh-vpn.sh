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
echo -e "${blue} ─────────────────────────────────────────${neutral}"
echo -e "${yellow}            SYSTEM OPTIMIZATION${neutral}"
echo -e "${blue} ─────────────────────────────────────────${neutral}"
echo ""

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${blue}   ${yellow}Copyright${reset} (C)${gray} https://t.me/frel01     ${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

# etc
run_with_spinner "Upgrading system packages..." apt dist-upgrade -y
run_with_spinner "Installing netfilter-persistent..." apt install netfilter-persistent -y
run_with_spinner "Removing ufw and firewalld..." apt-get remove --purge ufw firewalld -y
run_with_spinner "Installing essential packages..." apt install -y screen curl jq bzip2 gzip vnstat coreutils rsyslog iftop zip unzip git apt-transport-https build-essential

REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"
REPO2="https://raw.githubusercontent.com/PeyxDev/esce/main/install/autocpu.sh"

# initializing var
export DEBIAN_FRONTEND=noninteractive
MYIP=$(wget -qO- ipinfo.io/ip)
MYIP2="s/xxxxxxxxx/$MYIP/g"
NET=$(ip -o $ANU -4 route show to default | awk '{print $5}')

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID
    run_with_spinner "Detecting OS: $OS_NAME $OS_VERSION" sleep 1
else
    echo -e "${red}Unable to determine operating system${neutral}"
    exit 1
fi

# simple password minimal
run_with_spinner "Configuring password policies..." curl -sS ${REPO}install/password | openssl aes-256-cbc -d -a -pass pass:scvps07gg -pbkdf2 > /etc/pam.d/common-password
run_with_spinner "Setting password file permissions..." chmod +x /etc/pam.d/common-password

# go to root
cd

run_with_spinner "Configuring rc-local service..." bash -c 'cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END'

run_with_spinner "Creating rc.local script..." bash -c 'cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END'

run_with_spinner "Setting rc-local permissions..." chmod +x /etc/rc.local
run_with_spinner "Enabling rc-local service..." systemctl enable rc-local
run_with_spinner "Starting rc-local service..." systemctl start rc-local.service

# disable ipv6
run_with_spinner "Disabling IPv6..." bash -c 'echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6'
run_with_spinner "Adding IPv6 disable to rc.local..." sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

run_with_spinner "Updating package lists..." apt update -y
run_with_spinner "Upgrading system..." apt upgrade -y
run_with_spinner "Performing dist-upgrade..." apt dist-upgrade -y
run_with_spinner "Removing ufw and firewalld..." apt-get remove --purge ufw firewalld -y
run_with_spinner "Removing exim4..." apt-get remove --purge exim4 -y

run_with_spinner "Installing jq..." apt -y install jq
run_with_spinner "Installing shc..." apt -y install shc
run_with_spinner "Installing wget and curl..." apt -y install wget curl
run_with_spinner "Installing figlet and ruby..." apt-get install figlet ruby -y
run_with_spinner "Installing lolcat..." gem install lolcat

run_with_spinner "Setting timezone to GMT+7..." ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
run_with_spinner "Configuring SSH locale..." sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

run_with_spinner "Installing additional packages..." apt-get --reinstall --fix-missing install -y bzip2 gzip coreutils wget screen rsyslog iftop htop net-tools zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl neofetch git lsof

install_ssl(){
    if [ -f "/usr/bin/apt-get" ];then
            isDebian=`cat /etc/issue|grep Debian`
            if [ "$isDebian" != "" ];then
                    run_with_spinner "Installing nginx and certbot for Debian..." apt-get install -y nginx certbot
                    sleep 3s
            else
                    run_with_spinner "Installing nginx and certbot..." apt-get install -y nginx certbot
                    sleep 3s
            fi
    else
        run_with_spinner "Installing nginx and certbot for yum..." yum install -y nginx certbot
        sleep 3s
    fi

    run_with_spinner "Stopping nginx service..." systemctl stop nginx.service
}

run_with_spinner "Installing web server packages..." apt -y install nginx php php-fpm php-cli php-mysql libxml-parser-perl
run_with_spinner "Removing default nginx config..." rm /etc/nginx/sites-enabled/default
run_with_spinner "Removing default nginx sites..." rm /etc/nginx/sites-available/default
run_with_spinner "Downloading nginx configuration..." curl ${REPO}install/nginx.conf > /etc/nginx/nginx.conf
run_with_spinner "Downloading vps configuration..." curl ${REPO}install/vps.conf > /etc/nginx/conf.d/vps.conf
run_with_spinner "Configuring PHP-FPM..." sed -i 's/listen = \/var\/run\/php-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php/fpm/pool.d/www.conf
run_with_spinner "Creating web directory..." mkdir -p /home/vps/public_html
run_with_spinner "Creating phpinfo file..." echo "<?php phpinfo() ?>" > /home/vps/public_html/info.php
run_with_spinner "Setting web directory permissions..." chown -R www-data:www-data /home/vps/public_html
run_with_spinner "Setting directory permissions..." chmod -R g+rw /home/vps/public_html
cd /home/vps/public_html
run_with_spinner "Downloading index page..." wget -O /home/vps/public_html/index.html "${REPO}install/index.html1"
run_with_spinner "Restarting nginx..." /etc/init.d/nginx restart

run_with_spinner "Installing BadVPN..." cd
run_with_spinner "Downloading BadVPN binary..." wget -O /usr/sbin/badvpn "${REPO}install/badvpn" >/dev/null 2>&1
run_with_spinner "Setting BadVPN permissions..." chmod +x /usr/sbin/badvpn > /dev/null 2>&1
run_with_spinner "Downloading BadVPN service files..." wget -q -O /etc/systemd/system/badvpn1.service "${REPO}install/badvpn1.service" >/dev/null 2>&1
run_with_spinner "Downloading BadVPN service 2..." wget -q -O /etc/systemd/system/badvpn2.service "${REPO}install/badvpn2.service" >/dev/null 2>&1
run_with_spinner "Downloading BadVPN service 3..." wget -q -O /etc/systemd/system/badvpn3.service "${REPO}install/badvpn3.service" >/dev/null 2>&1

run_with_spinner "Configuring BadVPN services..." systemctl disable badvpn1 
run_with_spinner "Stopping BadVPN service 1..." systemctl stop badvpn1 
run_with_spinner "Enabling BadVPN service 1..." systemctl enable badvpn1
run_with_spinner "Starting BadVPN service 1..." systemctl start badvpn1 

run_with_spinner "Configuring SSH ports..." sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
run_with_spinner "Adding SSH port 500..." sed -i '/Port 22/a Port 500' /etc/ssh/sshd_config
run_with_spinner "Adding SSH port 40000..." sed -i '/Port 22/a Port 40000' /etc/ssh/sshd_config
run_with_spinner "Adding SSH port 51443..." sed -i '/Port 22/a Port 51443' /etc/ssh/sshd_config
run_with_spinner "Adding SSH port 58080..." sed -i '/Port 22/a Port 58080' /etc/ssh/sshd_config
run_with_spinner "Adding SSH port 200..." sed -i '/Port 22/a Port 200' /etc/ssh/sshd_config
run_with_spinner "Restarting SSH service..." /etc/init.d/ssh restart

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}📡 INSTALLING DROPBEAR${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Installing dropbear..." apt -y install dropbear
run_with_spinner "Generating dropbear keys..." sudo dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
run_with_spinner "Setting dropbear key permissions..." sudo chmod 600 /etc/dropbear/dropbear_dss_host_key
run_with_spinner "Downloading dropbear configuration..." wget -O /etc/default/dropbear "${REPO}install/dropbear"
run_with_spinner "Configuring shells..." echo "/bin/false" >> /etc/shells
run_with_spinner "Adding nologin to shells..." echo "/usr/sbin/nologin" >> /etc/shells
run_with_spinner "Restarting SSH service..." /etc/init.d/ssh restart
run_with_spinner "Restarting dropbear service..." /etc/init.d/dropbear restart
run_with_spinner "Configuring rsyslog..." wget -q ${REPO}install/setrsyslog.sh && chmod +x setrsyslog.sh && ./setrsyslog.sh

if [[ "$OS_NAME" == "debian" && "$OS_VERSION" == "10" ]] || [[ "$OS_NAME" == "ubuntu" && "$OS_VERSION" == "20.04" ]]; then
    run_with_spinner "Installing squid3 for Debian 10/Ubuntu 20.04..." apt -y install squid3
else
    run_with_spinner "Installing squid..." apt -y install squid
fi

run_with_spinner "Downloading squid configuration..." wget -O /etc/squid/squid.conf "${REPO}install/squid3.conf"
run_with_spinner "Configuring squid with current IP..." sed -i $MYIP2 /etc/squid/squid.conf

run_with_spinner "Installing vnstat..." apt -y install vnstat
run_with_spinner "Restarting vnstat..." /etc/init.d/vnstat restart
run_with_spinner "Installing sqlite3 dev..." apt -y install libsqlite3-dev
run_with_spinner "Downloading vnstat 2.6..." wget https://humdi.net/vnstat/vnstat-2.6.tar.gz
run_with_spinner "Extracting vnstat..." tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
run_with_spinner "Compiling vnstat..." ./configure --prefix=/usr --sysconfdir=/etc && make && make install
cd
run_with_spinner "Configuring vnstat interface..." vnstat -i $NET
run_with_spinner "Updating vnstat configuration..." sed -i 's/Interface "'""eth0""'"/Interface "'""$NET""'"/g' /etc/vnstat.conf
run_with_spinner "Setting vnstat permissions..." chown vnstat:vnstat /var/lib/vnstat -R
run_with_spinner "Enabling vnstat service..." systemctl enable vnstat
run_with_spinner "Restarting vnstat service..." /etc/init.d/vnstat restart
run_with_spinner "Cleaning vnstat files..." rm -f /root/vnstat-2.6.tar.gz
run_with_spinner "Removing vnstat source..." rm -rf /root/vnstat-2.6

cd
if dpkg -l | grep -q haproxy; then
    echo -e "HAProxy already installed ${green}✓${neutral}"
else
    run_with_spinner "Installing HAProxy..." apt install haproxy -y
fi

run_with_spinner "Downloading HAProxy configuration..." wget -O /etc/haproxy/haproxy.cfg "https://raw.githubusercontent.com/PeyxDev/esce/main/install/haproxy.cfg"
run_with_spinner "Reloading systemd daemon..." systemctl daemon-reload
run_with_spinner "Stopping HAProxy service..." systemctl stop haproxy
run_with_spinner "Enabling HAProxy service..." systemctl enable haproxy
run_with_spinner "Starting HAProxy service..." systemctl start haproxy

run_with_spinner "Installing OpenVPN..." wget ${REPO}install/vpn.sh && chmod +x vpn.sh && ./vpn.sh
run_with_spinner "Installing lolcat..." wget ${REPO}install/lolcat.sh && chmod +x lolcat.sh && ./lolcat.sh

run_with_spinner "Creating swap file..." dd if=/dev/zero of=/swapfile bs=2048 count=1048576
run_with_spinner "Setting up swap..." mkswap /swapfile
run_with_spinner "Setting swap permissions..." chown root:root /swapfile
run_with_spinner "Configuring swap permissions..." chmod 0600 /swapfile >/dev/null 2>&1
run_with_spinner "Activating swap..." swapon /swapfile >/dev/null 2>&1
run_with_spinner "Adding swap to fstab..." sed -i '$ i\/swapfile      swap swap   defaults    0 0' /etc/fstab

run_with_spinner "Installing fail2ban..." apt -y install fail2ban

if [ -d '/usr/local/ddos' ]; then
	echo -e "Previous version detected ${green}✓${neutral}"
else
	run_with_spinner "Creating ddos directory..." mkdir /usr/local/ddos
fi

run_with_spinner "Installing DOS-Deflate..." wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
run_with_spinner "Downloading LICENSE..." wget -q -O /usr/local/ddos/LICENSE http://www.inetbase.com/scripts/ddos/LICENSE
run_with_spinner "Downloading ignore IP list..." wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
run_with_spinner "Downloading ddos script..." wget -q -O /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
run_with_spinner "Setting script permissions..." chmod 0755 /usr/local/ddos/ddos.sh
run_with_spinner "Creating symlink..." cp -s /usr/local/ddos/ddos.sh /usr/local/bin/ddos
run_with_spinner "Setting up cron job..." /usr/local/ddos/ddos.sh --cron > /dev/null 2>&1

run_with_spinner "Configuring SSH banner..." echo "Banner /etc/issue.net" >>/etc/ssh/sshd_config
run_with_spinner "Downloading banner..." wget -O /etc/issue.net "${REPO}install/issue.net"

run_with_spinner "Installing BBR optimization..." wget ${REPO}install/bbr.sh && chmod +x bbr.sh && ./bbr.sh
run_with_spinner "Configuring IP server..." wget -q ${REPO}install/ipserver && chmod +x ipserver && ./ipserver

run_with_spinner "Configuring iptables rules..." iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
run_with_spinner "Adding torrent blocking rules..." iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
run_with_spinner "Adding node blocking rules..." iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
run_with_spinner "Adding BitTorrent blocking..." iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
run_with_spinner "Adding protocol blocking..." iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
run_with_spinner "Adding peer_id blocking..." iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
run_with_spinner "Adding torrent extension blocking..." iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
run_with_spinner "Adding announce.php blocking..." iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
run_with_spinner "Adding torrent keyword blocking..." iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
run_with_spinner "Adding announce blocking..." iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
run_with_spinner "Adding info_hash blocking..." iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
run_with_spinner "Saving iptables rules..." iptables-save > /etc/iptables.up.rules
run_with_spinner "Restoring iptables rules..." iptables-restore -t < /etc/iptables.up.rules
run_with_spinner "Saving netfilter rules..." netfilter-persistent save
run_with_spinner "Reloading netfilter..." netfilter-persistent reload
run_with_spinner "Cleaning up..." rm ipserver

run_with_spinner "Downloading updated banner..." wget -O /etc/issue.net "${REPO}install/issue.net"
cd

run_with_spinner "Setting up cron jobs..." bash -c 'cat> /etc/cron.d/xp_otm << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 0 * * * root /usr/local/sbin/xp
END'

run_with_spinner "Setting up backup cron..." bash -c 'cat> /etc/cron.d/bckp_otm << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 22 * * * root /usr/local/sbin/backup
END'

run_with_spinner "Setting up CPU monitoring cron..." bash -c 'cat> /etc/cron.d/cpu_otm << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * root /usr/bin/autocpu
END'

run_with_spinner "Downloading autocpu script..." wget -O /usr/bin/autocpu "${REPO2}" && chmod +x /usr/bin/autocpu

run_with_spinner "Setting up additional cron jobs..." bash -c 'cat >/etc/cron.d/xp_sc <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
1 0 * * * root /usr/local/sbin/expsc
END'

run_with_spinner "Setting up log cleanup cron..." bash -c 'cat >/etc/cron.d/logclean <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/10 * * * * root truncate -s 0 /var/log/syslog \
    && truncate -s 0 /var/log/nginx/error.log \
    && truncate -s 0 /var/log/nginx/access.log \
    && truncate -s 0 /var/log/xray/error.log \
    && truncate -s 0 /var/log/xray/access.log
END'

run_with_spinner "Setting up daily reboot cron..." bash -c 'cat >/etc/cron.d/daily_reboot <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
5 0 * * * root /sbin/reboot
END'

run_with_spinner "Restarting cron service..." service cron restart >/dev/null 2>&1
run_with_spinner "Reloading cron service..." service cron reload >/dev/null 2>&1
run_with_spinner "Starting cron service..." service cron start >/dev/null 2>&1

run_with_spinner "Cleaning package cache..." apt autoclean -y >/dev/null 2>&1
run_with_spinner "Removing unnecessary packages..." apt -y remove --purge unscd >/dev/null 2>&1
run_with_spinner "Removing samba..." apt-get -y --purge remove samba* >/dev/null 2>&1
run_with_spinner "Removing apache2..." apt-get -y --purge remove apache2* >/dev/null 2>&1
run_with_spinner "Removing bind9..." apt-get -y --purge remove bind9* >/dev/null 2>&1
run_with_spinner "Removing sendmail..." apt-get -y remove sendmail* >/dev/null 2>&1
run_with_spinner "Performing autoremove..." apt autoremove -y >/dev/null 2>&1

# finishing
cd
run_with_spinner "Setting web directory ownership..." chown -R www-data:www-data /home/vps/public_html

run_with_spinner "Cleaning up temporary files..." rm -f /root/key.pem
run_with_spinner "Removing certificate files..." rm -f /root/cert.pem
run_with_spinner "Removing installation scripts..." rm -f /root/ssh-vpn.sh
run_with_spinner "Removing BBR script..." rm -f /root/bbr.sh
run_with_spinner "Removing apache2 directory..." rm -rf /etc/apache2

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🎉 SYSTEM OPTIMIZATION COMPLETED ${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${yellow}All services have been installed and configured${neutral}"
echo -e "${blue}System is ready for use!${neutral}"
echo ""
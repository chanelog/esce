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

# etc
run_with_spinner "Upgrading system..." apt dist-upgrade -y
run_with_spinner "Installing netfilter-persistent..." apt install netfilter-persistent -y
run_with_spinner "Removing ufw and firewalld..." apt-get remove --purge ufw firewalld -y
run_with_spinner "Installing essential packages..." apt install -y screen curl jq bzip2 gzip vnstat coreutils rsyslog iftop zip unzip git apt-transport-https build-essential -y

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
    echo -e "${blue}Menemukan sistem operasi: $OS_NAME $OS_VERSION${neutral}"
else
    echo -e "${red}Tidak dapat menentukan sistem operasi.${neutral}"
    exit 1
fi

#detail nama perusahaan
country=ID
state=Indonesia
locality=Jakarta
organization=none
organizationalunit=none
commonname=none
email=none

# simple password minimal
run_with_spinner "Setting password policy..." curl -sS ${REPO}install/password | openssl aes-256-cbc -d -a -pass pass:scvps07gg -pbkdf2 > /etc/pam.d/common-password
chmod +x /etc/pam.d/common-password

# go to root
cd

run_with_spinner "Configuring rc-local service..." cat > /etc/systemd/system/rc-local.service <<-END
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
END

run_with_spinner "Creating rc.local..." cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

run_with_spinner "Setting rc-local permissions..." chmod +x /etc/rc.local
run_with_spinner "Enabling rc-local..." systemctl enable rc-local
run_with_spinner "Starting rc-local..." systemctl start rc-local.service

run_with_spinner "Disabling IPv6..." echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

run_with_spinner "Updating system packages..." apt update -y
run_with_spinner "Upgrading system..." apt upgrade -y
run_with_spinner "Dist-upgrading..." apt dist-upgrade -y
run_with_spinner "Removing ufw and firewalld..." apt-get remove --purge ufw firewalld -y
run_with_spinner "Removing exim4..." apt-get remove --purge exim4 -y

run_with_spinner "Installing jq..." apt -y install jq
run_with_spinner "Installing shc..." apt -y install shc
run_with_spinner "Installing wget and curl..." apt -y install wget curl
run_with_spinner "Installing figlet and lolcat..." apt-get install figlet -y
apt-get install ruby -y
gem install lolcat

run_with_spinner "Setting timezone..." ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
run_with_spinner "Configuring SSH..." sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

run_with_spinner "Installing additional packages..." apt-get --reinstall --fix-missing install -y bzip2 gzip coreutils wget screen rsyslog iftop htop net-tools zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl neofetch git lsof

install_ssl(){
    if [ -f "/usr/bin/apt-get" ];then
            isDebian=`cat /etc/issue|grep Debian`
            if [ "$isDebian" != "" ];then
                    apt-get install -y nginx certbot
                    apt install -y nginx certbot
                    sleep 3s
            else
                    apt-get install -y nginx certbot
                    apt install -y nginx certbot
                    sleep 3s
            fi
    else
        yum install -y nginx certbot
        sleep 3s
    fi

    systemctl stop nginx.service

    if [ -f "/usr/bin/apt-get" ];then
            isDebian=`cat /etc/issue|grep Debian`
            if [ "$isDebian" != "" ];then
                    echo "A" | certbot certonly --renew-by-default --register-unsafely-without-email --standalone -d $domain
                    sleep 3s
            else
                    echo "A" | certbot certonly --renew-by-default --register-unsafely-without-email --standalone -d $domain
                    sleep 3s
            fi
    else
        echo "Y" | certbot certonly --renew-by-default --register-unsafely-without-email --standalone -d $domain
        sleep 3s
    fi
}

# install webserver
run_with_spinner "Installing nginx and PHP..." apt -y install nginx php php-fpm php-cli php-mysql libxml-parser-perl
run_with_spinner "Configuring nginx..." rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
curl ${REPO}install/nginx.conf > /etc/nginx/nginx.conf
curl ${REPO}install/vps.conf > /etc/nginx/conf.d/vps.conf
sed -i 's/listen = \/var\/run\/php-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php/fpm/pool.d/www.conf
mkdir -p /home/vps/public_html
echo "<?php phpinfo() ?>" > /home/vps/public_html/info.php
chown -R www-data:www-data /home/vps/public_html
chmod -R g+rw /home/vps/public_html
cd /home/vps/public_html
wget -O /home/vps/public_html/index.html "${REPO}install/index.html1"
run_with_spinner "Restarting nginx..." /etc/init.d/nginx restart

# install badvpn
cd
run_with_spinner "Installing badvpn..." wget -O /usr/sbin/badvpn "${REPO}install/badvpn" >/dev/null 2>&1
chmod +x /usr/sbin/badvpn > /dev/null 2>&1
wget -q -O /etc/systemd/system/badvpn1.service "${REPO}install/badvpn1.service" >/dev/null 2>&1
wget -q -O /etc/systemd/system/badvpn2.service "${REPO}install/badvpn2.service" >/dev/null 2>&1
wget -q -O /etc/systemd/system/badvpn3.service "${REPO}install/badvpn3.service" >/dev/null 2>&1
systemctl disable badvpn1 
systemctl stop badvpn1 
systemctl enable badvpn1
systemctl start badvpn1 
systemctl disable badvpn2 
systemctl stop badvpn2 
systemctl enable badvpn2
systemctl start badvpn2 
systemctl disable badvpn3 
systemctl stop badvpn3 
systemctl enable badvpn3
systemctl start badvpn3 

# setting port ssh
cd
run_with_spinner "Configuring SSH ports..." sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 500' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 40000' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 51443' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 58080' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 200' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 22' /etc/ssh/sshd_config
run_with_spinner "Restarting SSH..." /etc/init.d/ssh restart

echo -e "${blue}=== Install Dropbear ===${neutral}"
run_with_spinner "Installing dropbear..." apt -y install dropbear
sudo dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
sudo chmod 600 /etc/dropbear/dropbear_dss_host_key
wget -O /etc/default/dropbear "${REPO}install/dropbear"
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/ssh restart
/etc/init.d/dropbear restart
wget -q ${REPO}install/setrsyslog.sh && chmod +x setrsyslog.sh && ./setrsyslog.sh

run_with_spinner "Installing squid..." if [[ "$OS_NAME" == "debian" && "$OS_VERSION" == "10" ]] || [[ "$OS_NAME" == "ubuntu" && "$OS_VERSION" == "20.04" ]]; then
    echo -e "${yellow}Menginstal squid3 untuk Debian 10 atau Ubuntu 20.04...${neutral}"
    apt -y install squid3
else
    echo -e "${yellow}Menginstal squid untuk versi lain...${neutral}"
    apt -y install squid
fi

run_with_spinner "Configuring squid..." wget -O /etc/squid/squid.conf "${REPO}install/squid3.conf"
sed -i $MYIP2 /etc/squid/squid.conf

# setting vnstat
run_with_spinner "Installing vnstat..." apt -y install vnstat
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev
wget https://humdi.net/vnstat/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc && make && make install
cd
vnstat -i $NET
sed -i 's/Interface "'""eth0""'"/Interface "'""$NET""'"/g' /etc/vnstat.conf
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -f /root/vnstat-2.6.tar.gz
rm -rf /root/vnstat-2.6

cd
# install haproxy
run_with_spinner "Installing haproxy..." if dpkg -l | grep -q haproxy; then
    echo -e "${yellow}HAProxy sudah terinstal. Melanjutkan ke langkah berikutnya...${neutral}"
else
    echo -e "${yellow}HAProxy belum terinstal. Menginstal HAProxy...${neutral}"
    apt install haproxy -y
fi

run_with_spinner "Configuring haproxy..." wget -O /etc/haproxy/haproxy.cfg "https://raw.githubusercontent.com/PeyxDev/esce/main/install/haproxy.cfg"
systemctl daemon-reload
systemctl stop haproxy
systemctl enable haproxy
systemctl start haproxy

#OpenVPN
run_with_spinner "Installing OpenVPN..." wget ${REPO}install/vpn.sh &&  chmod +x vpn.sh && ./vpn.sh

# install lolcat
run_with_spinner "Installing lolcat..." wget ${REPO}install/lolcat.sh &&  chmod +x lolcat.sh && ./lolcat.sh

# memory swap 1gb
cd
run_with_spinner "Creating swap file..." dd if=/dev/zero of=/swapfile bs=2048 count=1048576
mkswap /swapfile
chown root:root /swapfile
chmod 0600 /swapfile >/dev/null 2>&1
swapon /swapfile >/dev/null 2>&1
sed -i '$ i\/swapfile      swap swap   defaults    0 0' /etc/fstab

run_with_spinner "Installing fail2ban..." apt -y install fail2ban

# Instal DDOS Flate
run_with_spinner "Installing DOS-Deflate..." if [ -d '/usr/local/ddos' ]; then
	echo; echo; echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/ddos
fi

wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
wget -q -O /usr/local/ddos/LICENSE http://www.inetbase.com/scripts/ddos/LICENSE
wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
wget -q -O /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
cp -s /usr/local/ddos/ddos.sh /usr/local/bin/ddos
/usr/local/ddos/ddos.sh --cron > /dev/null 2>&1

# banner /etc/issue.net
run_with_spinner "Configuring SSH banner..." echo "Banner /etc/issue.net" >>/etc/ssh/sshd_config
wget -O /etc/issue.net "${REPO}install/issue.net"

#install bbr dan optimasi kernel
run_with_spinner "Installing BBR..." wget ${REPO}install/bbr.sh && chmod +x bbr.sh && ./bbr.sh

run_with_spinner "Configuring IP server..." wget -q ${REPO}install/ipserver && chmod +x ipserver && ./ipserver

# blokir torrent
run_with_spinner "Blocking torrent traffic..." iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload
rm ipserver

# download script
run_with_spinner "Downloading scripts..." wget -O /etc/issue.net "${REPO}install/issue.net"
cd

run_with_spinner "Setting up cron jobs..." cat> /etc/cron.d/xp_otm << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 0 * * * root /usr/local/sbin/xp
END

cat> /etc/cron.d/bckp_otm << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 22 * * * root /usr/local/sbin/backup
END

cat> /etc/cron.d/cpu_otm << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * root /usr/bin/autocpu
END

wget -O /usr/bin/autocpu "${REPO2}" && chmod +x /usr/bin/autocpu

cat >/etc/cron.d/xp_sc <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		1 0 * * * root /usr/local/sbin/expsc
	END

cat >/etc/cron.d/logclean <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/10 * * * * root truncate -s 0 /var/log/syslog \
    && truncate -s 0 /var/log/nginx/error.log \
    && truncate -s 0 /var/log/nginx/access.log \
    && truncate -s 0 /var/log/xray/error.log \
    && truncate -s 0 /var/log/xray/access.log
END

cat >/etc/cron.d/daily_reboot <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
5 0 * * * root /sbin/reboot
END

run_with_spinner "Restarting cron..." service cron restart >/dev/null 2>&1
service cron reload >/dev/null 2>&1
service cron start >/dev/null 2>&1

# remove unnecessary files
run_with_spinner "Cleaning up..." apt autoclean -y >/dev/null 2>&1
apt -y remove --purge unscd >/dev/null 2>&1
apt-get -y --purge remove samba* >/dev/null 2>&1
apt-get -y --purge remove apache2* >/dev/null 2>&1
apt-get -y --purge remove bind9* >/dev/null 2>&1
apt-get -y remove sendmail* >/dev/null 2>&1
apt autoremove -y >/dev/null 2>&1

# finishing
cd
run_with_spinner "Setting permissions..." chown -R www-data:www-data /home/vps/public_html

rm -f /root/key.pem
rm -f /root/cert.pem
rm -f /root/ssh-vpn.sh
rm -f /root/bbr.sh
rm -rf /etc/apache2

echo -e "${blue}==================================================${neutral}"
echo -e "${green}System Installation Completed Successfully!${neutral}"
echo -e "${yellow}All services and configurations have been installed.${neutral}"
echo -e "${blue}==================================================${neutral}"
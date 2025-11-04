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
echo -e "${blue}==========================================${neutral}"

# Getting
REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"
echo -e ""
date
echo ""
cd
if [[ -e /etc/xray/domain ]]; then
domain=$(cat /etc/xray/domain)
else
domain=$(cat /etc/xray/domain) 
fi

run_with_spinner "Checking system..." sleep 0.1

run_with_spinner "Installing iptables..." apt install iptables iptables-persistent -y

run_with_spinner "Setting ntpdate..." ntpdate pool.ntp.org
timedatectl set-ntp true

run_with_spinner "Enabling chrony..." systemctl enable chrony
systemctl restart chrony
timedatectl set-timezone Asia/Jakarta

run_with_spinner "Setting chrony tracking..." chronyc sourcestats -v
chronyc tracking -v

run_with_spinner "Updating packages..." apt clean all && apt update

run_with_spinner "Installing dependencies..." apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y
apt install socat cron bash-completion ntpdate -y
ntpdate pool.ntp.org
apt -y install chrony
apt install zip -y
apt install curl pwgen openssl cron -y

# install xray
run_with_spinner "Downloading & Installing xray core..." domainSock_dir="/run/xray";! [ -d $domainSock_dir ] && mkdir  $domainSock_dir
chown www-data.www-data $domainSock_dir

# Make Folder XRay
run_with_spinner "Creating Xray directories..." mkdir -p /var/log/xray
mkdir -p /etc/xray
chown www-data.www-data /var/log/xray
chmod +x /var/log/xray
touch /var/log/xray/access.log
touch /var/log/xray/error.log
touch /var/log/xray/access2.log
touch /var/log/xray/error2.log

# / / Ambil Xray Core Version Terbaru
run_with_spinner "Installing Xray core..." latest_version="24.11.30"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version $latest_version

## crt xray
run_with_spinner "Stopping services..." systemctl stop nginx
systemctl stop haproxy

run_with_spinner "Setting up SSL certificate..." mkdir /root/.acme.sh
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc

# nginx renew ssl
run_with_spinner "Setting up SSL renewal..." echo -n '#!/bin/bash
/etc/init.d/nginx stop
"/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" &> /root/renew_ssl.log
/etc/init.d/nginx start
/etc/init.d/nginx status
' > /usr/local/bin/ssl_renew.sh
chmod +x /usr/local/bin/ssl_renew.sh
if ! grep -q 'ssl_renew.sh' /var/spool/cron/crontabs/root;then (crontab -l;echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab;fi

run_with_spinner "Creating web directory..." mkdir -p /home/vps/public_html

# set uuid
run_with_spinner "Generating UUID..." uuid=$(cat /proc/sys/kernel/random/uuid)

# xray config
run_with_spinner "Configuring Xray..." cat > /etc/xray/config.json << END
{
  "log" : {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
      {
      "listen": "127.0.0.1",
      "port": 10000,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
   {
     "listen": "127.0.0.1",
     "port": "10001",
     "protocol": "vless",
      "settings": {
          "decryption":"none",
            "clients": [
               {
                 "id": "${uuid}"                 
#vless
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/vless"
          }
        }
     },
     {
     "listen": "127.0.0.1",
     "port": "10002",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmess
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/vmess"
          }
        }
     },
    {
      "listen": "127.0.0.1",
      "port": "10003",
      "protocol": "trojan",
      "settings": {
          "decryption":"none",		
           "clients": [
              {
                 "password": "${uuid}"
#trojanws
              }
          ],
         "udp": true
       },
       "streamSettings":{
           "network": "ws",
           "wsSettings": {
               "path": "/trojan"
            }
         }
     },
    {
         "listen": "127.0.0.1",
        "port": "10004",
        "protocol": "shadowsocks",
        "settings": {
           "clients": [
           {
           "method": "aes-128-gcm",
          "password": "${uuid}"
#ssws
           }
          ],
          "network": "tcp,udp"
       },
       "streamSettings":{
          "network": "ws",
             "wsSettings": {
               "path": "/ss-ws"
           }
        }
     },	
      {
        "listen": "127.0.0.1",
     "port": "10005",
        "protocol": "vless",
        "settings": {
         "decryption":"none",
           "clients": [
             {
               "id": "${uuid}"
#vlessgrpc
             }
          ]
       },
          "streamSettings":{
             "network": "grpc",
             "grpcSettings": {
                "serviceName": "vless-grpc"
           }
        }
     },
     {
      "listen": "127.0.0.1",
     "port": "10006",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmessgrpc
             }
          ]
       },
       "streamSettings":{
         "network": "grpc",
            "grpcSettings": {
                "serviceName": "vmess-grpc"
          }
        }
     },
     {
        "listen": "127.0.0.1",
     "port": "10007",
        "protocol": "trojan",
        "settings": {
          "decryption":"none",
             "clients": [
               {
                 "password": "${uuid}"
#trojangrpc
               }
           ]
        },
         "streamSettings":{
         "network": "grpc",
           "grpcSettings": {
               "serviceName": "trojan-grpc"
         }
      }
   },
   {
    "listen": "127.0.0.1",
    "port": "10008",
    "protocol": "shadowsocks",
    "settings": {
        "clients": [
          {
             "method": "aes-128-gcm",
             "password": "${uuid}"
#ssgrpc
           }
         ],
           "network": "tcp,udp"
      },
    "streamSettings":{
     "network": "grpc",
        "grpcSettings": {
           "serviceName": "ss-grpc"
          }
       }
    }	
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END

run_with_spinner "Cleaning up service files..." rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service

run_with_spinner "Creating Xray service..." cat <<EOF> /etc/systemd/system/xray.service
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

EOF

run_with_spinner "Creating run service..." cat > /etc/systemd/system/runn.service <<EOF
[Unit]
Description=casper9
After=network.target

[Service]
Type=simple
ExecStartPre=-/usr/bin/mkdir -p /var/run/xray
ExecStart=/usr/bin/chown www-data:www-data /var/run/xray
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

#nginx config
run_with_spinner "Downloading configuration files..." wget -O /etc/nginx/conf.d/xray.conf "${REPO}install/xray.conf"
wget -O /etc/haproxy/haproxy.cfg "${REPO}install/haproxy.cfg"
sed -i 's/xxx/$domain/' /etc/nginx/conf.d/xray.conf
sed -i 's/xxx/$domain/' /etc/haproxy/haproxy.cfg
cat /etc/xray/xray.key /etc/xray/xray.crt | tee /etc/haproxy/hap.pem

echo -e "${yellow}Restarting All Services${neutral}"
systemctl daemon-reload

run_with_spinner "Enabling & restarting Xray..." systemctl daemon-reload
systemctl enable xray
systemctl restart xray

run_with_spinner "Restarting Nginx..." systemctl restart nginx

run_with_spinner "Enabling & restarting HAProxy..." systemctl enable haproxy
systemctl restart haproxy

run_with_spinner "Enabling & restarting run service..." systemctl enable runn
systemctl restart runn

run_with_spinner "Finalizing setup..." mv /root/domain /etc/xray/
if [ -f /root/scdomain ];then
rm /root/scdomain > /dev/null 2>&1
fi

echo -e "${purple}==========================================${neutral}"
echo -e "${green}Xray Installation Completed Successfully!${neutral}"
echo -e "${blue}Protocols installed:${neutral}"
echo -e "${yellow}• xray/Vmess${neutral}"
echo -e "${yellow}• xray/Vless${neutral}"
echo -e "${purple}==========================================${neutral}"

run_with_spinner "Cleaning up..." rm -r ins-xray.sh

echo -e "${green}✅ All done! Script cleanup completed.${neutral}"
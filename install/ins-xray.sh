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
echo -e "${yellow}              XRAY CORE INSTALLATION${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${gray}✨ FILE ENC BY PeyxDev${neutral}"
echo ""

# Getting
REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}📅 SYSTEM INFORMATION${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
date
echo ""

cd
if [[ -e /etc/xray/domain ]]; then
    domain=$(cat /etc/xray/domain)
else
    domain=$(cat /etc/xray/domain) 
fi

run_with_spinner "Checking system requirements..." sleep 0.5
run_with_spinner "Installing iptables and persistent..." apt install iptables iptables-persistent -y
run_with_spinner "Setting up ntpdate..." ntpdate pool.ntp.org
run_with_spinner "Configuring system time..." timedatectl set-ntp true
run_with_spinner "Enabling chrony service..." systemctl enable chrony
run_with_spinner "Restarting chrony service..." systemctl restart chrony
run_with_spinner "Setting timezone to Jakarta..." timedatectl set-timezone Asia/Jakarta
run_with_spinner "Configuring chrony tracking..." chronyc sourcestats -v
run_with_spinner "Verifying time synchronization..." chronyc tracking -v

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}📦 INSTALLING DEPENDENCIES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Cleaning package cache..." apt clean all && apt update
run_with_spinner "Installing network tools..." apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y
run_with_spinner "Installing system utilities..." apt install socat cron bash-completion ntpdate -y
run_with_spinner "Synchronizing time..." ntpdate pool.ntp.org
run_with_spinner "Installing chrony..." apt -y install chrony
run_with_spinner "Installing compression tools..." apt install zip -y
run_with_spinner "Installing security tools..." apt install curl pwgen openssl cron -y

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🚀 INSTALLING XRAY CORE${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

domainSock_dir="/run/xray"
! [ -d $domainSock_dir ] && run_with_spinner "Creating Xray socket directory..." mkdir $domainSock_dir
run_with_spinner "Setting socket permissions..." chown www-data.www-data $domainSock_dir

run_with_spinner "Creating Xray log directories..." mkdir -p /var/log/xray
run_with_spinner "Creating Xray config directory..." mkdir -p /etc/xray
run_with_spinner "Setting log ownership..." chown www-data.www-data /var/log/xray
run_with_spinner "Setting log permissions..." chmod +x /var/log/xray
run_with_spinner "Creating log files..." touch /var/log/xray/access.log /var/log/xray/error.log /var/log/xray/access2.log /var/log/xray/error2.log

latest_version="24.11.30"
run_with_spinner "Downloading and installing Xray core v$latest_version..." bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version $latest_version

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔐 CONFIGURING SSL CERTIFICATE${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Stopping services for SSL setup..." systemctl stop nginx && systemctl stop haproxy
run_with_spinner "Creating ACME directory..." mkdir /root/.acme.sh
run_with_spinner "Downloading ACME script..." curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
run_with_spinner "Setting ACME permissions..." chmod +x /root/.acme.sh/acme.sh
run_with_spinner "Upgrading ACME script..." /root/.acme.sh/acme.sh --upgrade --auto-upgrade
run_with_spinner "Setting default CA..." /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
run_with_spinner "Issuing SSL certificate for $domain..." /root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
run_with_spinner "Installing certificate..." ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc

run_with_spinner "Creating SSL renewal script..." bash -c 'echo -n "#!/bin/bash
/etc/init.d/nginx stop
\"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" &> /root/renew_ssl.log
/etc/init.d/nginx start
/etc/init.d/nginx status
" > /usr/local/bin/ssl_renew.sh'

run_with_spinner "Setting renewal script permissions..." chmod +x /usr/local/bin/ssl_renew.sh

if ! grep -q 'ssl_renew.sh' /var/spool/cron/crontabs/root;then 
    run_with_spinner "Adding SSL renewal to cron..." (crontab -l;echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab
fi

run_with_spinner "Creating web directory..." mkdir -p /home/vps/public_html

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}⚙️  CONFIGURING XRAY SERVICES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

uuid=$(cat /proc/sys/kernel/random/uuid)
run_with_spinner "Generating UUID and creating Xray config..." bash -c 'cat > /etc/xray/config.json << END
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
END'

run_with_spinner "Cleaning old service files..." rm -rf /etc/systemd/system/xray.service.d /etc/systemd/system/xray@.service

run_with_spinner "Creating Xray service..." bash -c 'cat <<EOF> /etc/systemd/system/xray.service
[Unit]
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
EOF'

run_with_spinner "Creating runtime service..." bash -c 'cat > /etc/systemd/system/runn.service <<EOF
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
EOF'

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🌐 CONFIGURING PROXY SERVICES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Downloading Nginx configuration..." wget -O /etc/nginx/conf.d/xray.conf "${REPO}install/xray.conf"
run_with_spinner "Downloading HAProxy configuration..." wget -O /etc/haproxy/haproxy.cfg "${REPO}install/haproxy.cfg"
run_with_spinner "Configuring domain in Nginx..." sed -i "s/xxx/$domain/" /etc/nginx/conf.d/xray.conf
run_with_spinner "Configuring domain in HAProxy..." sed -i "s/xxx/$domain/" /etc/haproxy/haproxy.cfg
run_with_spinner "Creating HAProxy certificate..." cat /etc/xray/xray.key /etc/xray/xray.crt | tee /etc/haproxy/hap.pem

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔄 STARTING SERVICES${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Reloading system daemon..." systemctl daemon-reload
run_with_spinner "Enabling Xray service..." systemctl enable xray
run_with_spinner "Starting Xray service..." systemctl restart xray
run_with_spinner "Restarting Nginx..." systemctl restart nginx
run_with_spinner "Enabling HAProxy..." systemctl enable haproxy
run_with_spinner "Starting HAProxy..." systemctl restart haproxy
run_with_spinner "Enabling runtime service..." systemctl enable runn
run_with_spinner "Starting runtime service..." systemctl restart runn

run_with_spinner "Finalizing installation..." mv /root/domain /etc/xray/

if [ -f /root/scdomain ];then
    run_with_spinner "Cleaning up domain files..." rm /root/scdomain > /dev/null 2>&1
fi

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🎉 XRAY INSTALLATION COMPLETED${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${yellow}Services installed and configured:${neutral}"
echo -e "${blue}• Xray Core${neutral}"
echo -e "${blue}• Vmess Protocol${neutral}"
echo -e "${blue}• Vless Protocol${neutral}"
echo -e "${blue}• Trojan Protocol${neutral}"
echo -e "${blue}• Shadowsocks Protocol${neutral}"
echo -e "${green}All services are now running!${neutral}"
echo ""

run_with_spinner "Cleaning up installation script..." rm -f ins-xray.sh
#!/bin/bash
echo "✨ XRAY ULTIMATE INSTALLER - PEYX TUNNEL (FIXED)"
# ==========================================
# Color
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
# ==========================================

REPO="https://raw.githubusercontent.com/PeyxDev/esce/main/"
echo -e ""
date
echo ""

cd
if [[ -e /etc/xray/domain ]]; then
    domain=$(cat /etc/xray/domain)
else
    echo -e "[ ${RED}ERROR${NC} ] Domain file not found!"
    exit 1
fi

sleep 0.1
echo -e "[ ${GREEN}INFO${NC} ] Checking... "
apt install iptables iptables-persistent -y
sleep 0.1

echo -e "[ ${GREEN}INFO${NC} ] Install time synchronization tools"
apt install chrony ntpdate -y

echo -e "[ ${GREEN}INFO${NC} ] Setting ntpdate"
ntpdate pool.ntp.org
timedatectl set-ntp true

echo -e "[ ${GREEN}INFO${NC} ] Enable chrony"
systemctl enable chrony
systemctl restart chrony
timedatectl set-timezone Asia/Jakarta

sleep 0.1
echo -e "[ ${GREEN}INFO${NC} ] Setting chrony tracking"
chronyc sourcestats -v
chronyc tracking -v

echo -e "[ ${GREEN}INFO${NC} ] Setting dll"
apt clean all && apt update
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y
apt install socat cron bash-completion -y
ntpdate pool.ntp.org
apt install zip -y
apt install curl pwgen openssl cron net-tools jq -y

# ✅ FIX #1: TUNING KERNEL - Penyebab utama koneksi putus-putus
echo -e "[ ${GREEN}INFO${NC} ] Applying kernel network tuning..."
cat > /etc/sysctl.d/99-xray-tune.conf << 'SYSCTL'
# ── TCP Connection Stability ──────────────────────────────
# Jumlah max koneksi yang bisa di-queue (default terlalu kecil)
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535

# Buffer TCP - cegah packet loss & koneksi drop
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728

# ── TCP Keepalive - Cegah koneksi "mati suri" ─────────────
# Kirim keepalive probe setelah 60 detik idle
net.ipv4.tcp_keepalive_time = 60
# Interval antar probe: 10 detik
net.ipv4.tcp_keepalive_intvl = 10
# Jumlah probe sebelum putus: 6x
net.ipv4.tcp_keepalive_probes = 6

# ── FIN_WAIT & TIME_WAIT - Recycle koneksi lama ───────────
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 400000

# ── Congestion Control - BBR untuk performa terbaik ───────
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# ── Misc stability ────────────────────────────────────────
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_slow_start_after_idle = 0
SYSCTL

sysctl -p /etc/sysctl.d/99-xray-tune.conf
echo -e "[ ${GREEN}OK${NC} ] Kernel tuning applied"

# ✅ FIX #2: Aktifkan BBR jika kernel mendukung
if modprobe tcp_bbr 2>/dev/null; then
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    echo -e "[ ${GREEN}OK${NC} ] BBR enabled"
else
    echo -e "[ ${ORANGE}WARN${NC} ] BBR not available, using cubic"
fi

# install xray
sleep 0.1
echo -e "[ ${GREEN}INFO${NC} ] Downloading & Installing xray core"
domainSock_dir="/run/xray";! [ -d $domainSock_dir ] && mkdir $domainSock_dir
chown www-data.www-data $domainSock_dir

mkdir -p /var/log/xray
mkdir -p /usr/local/etc/xray
mkdir -p /etc/xray
mkdir -p /etc/peyx/{vmess,vless,trojan,log,limit/{vmess,vless,trojan}/ip}
chown www-data.www-data /var/log/xray
chmod +x /var/log/xray
touch /var/log/xray/access.log
touch /var/log/xray/error.log

latest_version="24.11.30"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version $latest_version

## MEMBUAT SSL CERTIFICATE (SELF-SIGNED)
echo -e "[ ${GREEN}INFO${NC} ] Creating SSL Certificate..."
systemctl stop nginx
systemctl stop haproxy 2>/dev/null

[ -f /etc/xray/xray.key ] && cp /etc/xray/xray.key /etc/xray/xray.key.bak
[ -f /etc/xray/xray.crt ] && cp /etc/xray/xray.crt /etc/xray/xray.crt.bak

openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=ID/ST=Jawa Barat/L=Sukabumi/O=PEYX TUNNEL/CN=$domain" \
    -keyout /etc/xray/xray.key \
    -out /etc/xray/xray.crt 2>/dev/null

chmod 644 /etc/xray/xray.{crt,key}
echo -e "[ ${GREEN}INFO${NC} ] SSL Certificate selesai"

mkdir -p /home/vps/public_html

uuid=$(cat /proc/sys/kernel/random/uuid)

echo "### vmess1 $(date -d '30 days' +%Y-%m-%d) $uuid 10 2" > /etc/peyx/vmess.db
echo "### vless1 $(date -d '30 days' +%Y-%m-%d) $uuid 10 2" > /etc/peyx/vless.db
echo "### trojan1 $(date -d '30 days' +%Y-%m-%d) $uuid 10 2" > /etc/peyx/trojan.db

echo "2" > /etc/peyx/limit/vmess/ip/vmess1
echo "2" > /etc/peyx/limit/vless/ip/vless1
echo "2" > /etc/peyx/limit/trojan/ip/trojan1

# ✅ FIX #3: Xray config dengan timeout & sniffing yang proper
cat > /usr/local/etc/xray/config.json << END
{
  "log": {
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
      "port": 10001,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless",
          "headers": {}
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "tag": "vless"
    },
    {
      "listen": "127.0.0.1",
      "port": 10002,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess",
          "headers": {}
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "tag": "vmess"
    },
    {
      "listen": "127.0.0.1",
      "port": 10003,
      "protocol": "trojan",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "password": "$uuid"
          }
        ],
        "udp": true
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojan",
          "headers": {}
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "tag": "trojan"
    },
    {
      "listen": "127.0.0.1",
      "port": 10004,
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
          {
            "method": "aes-128-gcm",
            "password": "$uuid"
          }
        ],
        "network": "tcp,udp"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/ss-ws",
          "headers": {}
        }
      },
      "tag": "shadowsocks"
    },
    {
      "listen": "127.0.0.1",
      "port": 10005,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid"
          }
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "vless-grpc",
          "idle_timeout": 60,
          "health_check_timeout": 20,
          "permit_without_stream": false
        }
      },
      "tag": "vless-grpc"
    },
    {
      "listen": "127.0.0.1",
      "port": 10006,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "vmess-grpc",
          "idle_timeout": 60,
          "health_check_timeout": 20,
          "permit_without_stream": false
        }
      },
      "tag": "vmess-grpc"
    },
    {
      "listen": "127.0.0.1",
      "port": 10007,
      "protocol": "trojan",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "password": "$uuid"
          }
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "trojan-grpc",
          "idle_timeout": 60,
          "health_check_timeout": 20,
          "permit_without_stream": false
        }
      },
      "tag": "trojan-grpc"
    },
    {
      "listen": "127.0.0.1",
      "port": 10008,
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
          {
            "method": "aes-128-gcm",
            "password": "$uuid"
          }
        ],
        "network": "tcp,udp"
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "ss-grpc",
          "idle_timeout": 60,
          "health_check_timeout": 20,
          "permit_without_stream": false
        }
      },
      "tag": "shadowsocks-grpc"
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIPv4"
      },
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "inboundTag": ["api"],
        "outboundTag": "api"
      },
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "protocol": ["bittorrent"],
        "outboundTag": "blocked"
      }
    ]
  },
  "policy": {
    "levels": {
      "0": {
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 2,
        "downlinkOnly": 5,
        "statsUserUplink": true,
        "statsUserDownlink": true,
        "bufferSize": 512
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink": true,
      "statsOutboundDownlink": true
    }
  },
  "stats": {},
  "api": {
    "services": ["StatsService"],
    "tag": "api"
  }
}
END

cp /usr/local/etc/xray/config.json /etc/xray/config.json 2>/dev/null

rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service

# ✅ FIX #4: Systemd service dengan restart yang lebih agresif & file limit besar
cat <<EOF> /etc/systemd/system/xray.service
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=always
RestartSec=3s
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000
# ✅ FIX: Tambah timeout agar service tidak hang
TimeoutStartSec=30
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/runn.service <<EOF
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

# ✅ FIX #5: ulimit untuk user www-data (cegah "too many open files")
mkdir -p /etc/security/limits.d/
cat > /etc/security/limits.d/xray.conf << 'LIMITS'
www-data soft nofile 1000000
www-data hard nofile 1000000
www-data soft nproc  65535
www-data hard nproc  65535
root     soft nofile 1000000
root     hard nofile 1000000
LIMITS

# nginx & haproxy config
wget -O /etc/nginx/conf.d/xray.conf "${REPO}install/xray.conf"
wget -O /etc/haproxy/haproxy.cfg "${REPO}install/haproxy.cfg"
sed -i "s/xxx/${domain}/" /etc/nginx/conf.d/xray.conf
sed -i "s/xxx/${domain}/" /etc/haproxy/haproxy.cfg
cat /etc/xray/xray.key /etc/xray/xray.crt | tee /etc/haproxy/hap.pem

# ✅ FIX #6: Benar pakai ${GREEN} bukan ${green} (typo di original)
echo -e "[ ${GREEN}INFO${NC} ] Restart All service"
systemctl daemon-reload
sleep 0.1
echo -e "[ ${GREEN}OK${NC} ] Enable & restart xray"
systemctl enable xray
systemctl restart xray
systemctl restart nginx
systemctl enable haproxy
systemctl restart haproxy
systemctl enable runn
systemctl restart runn

# ✅ FIX #7: Watchdog script - auto restart xray jika mati
cat > /usr/local/bin/xray-watchdog.sh << 'WATCHDOG'
#!/bin/bash
if ! systemctl is-active --quiet xray; then
    echo "[$(date)] Xray mati! Restarting..." >> /var/log/xray/watchdog.log
    systemctl restart xray
fi
WATCHDOG
chmod +x /usr/local/bin/xray-watchdog.sh

# Tambah ke cron setiap 2 menit
(crontab -l 2>/dev/null; echo "*/2 * * * * /usr/local/bin/xray-watchdog.sh") | crontab -
echo -e "[ ${GREEN}OK${NC} ] Watchdog cron installed"

sleep 0.1
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
yellow "xray/Vmess"
yellow "xray/Vless"

mv /root/domain /etc/xray/ 2>/dev/null
if [ -f /root/scdomain ]; then
    rm /root/scdomain > /dev/null 2>&1
fi
clear
rm -r ins-xray.sh

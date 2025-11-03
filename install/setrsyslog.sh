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

# Fungsi untuk mendeteksi sistem operasi dan versinya
detect_os() {
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    echo "$ID $VERSION_ID"  # Mengembalikan ID dan versi OS
  else
    echo "Unknown"
  fi
}

# Fungsi untuk mengecek dan mengatur izin dan kepemilikan file log
set_permissions() {
  local LOG_FILES=(
    "/var/log/auth.log"
    "/var/log/kern.log"
    "/var/log/mail.log"
    "/var/log/user.log"
    "/var/log/cron.log"
  )

  for log_file in "${LOG_FILES[@]}"; do
    if [[ -f "$log_file" ]]; then
      run_with_spinner "Setting permissions for $log_file" chmod 640 "$log_file"
      run_with_spinner "Setting ownership for $log_file" chown syslog:adm "$log_file"
    else
      echo -e " ${yellow}$log_file not found, skipping...${neutral}"
    fi
  done
}

# Mengecek apakah konfigurasi untuk dropbear sudah ada
check_dropbear_log() {
  grep -q 'if \$programname == "dropbear"' "$RSYSLOG_FILE"
}

# Fungsi untuk menambahkan konfigurasi dropbear
add_dropbear_log() {
  run_with_spinner "Adding Dropbear configuration to $RSYSLOG_FILE" bash -c "echo -e 'if \$programname == \"dropbear\" then /var/log/auth.log\n& stop' >> $RSYSLOG_FILE"
  run_with_spinner "Restarting rsyslog service" systemctl restart rsyslog
}

clear
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${yellow}           RSYSLOG CONFIGURATION SETUP${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔍 DETECTING OPERATING SYSTEM${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Detecting OS and version..." os_version=$(detect_os)
echo -e " Detected: ${yellow}$os_version${neutral}"

# Mengatur file konfigurasi Rsyslog berdasarkan OS dan versinya
if [[ "$os_version" == "ubuntu 24.04" ]]; then
  RSYSLOG_FILE="/etc/rsyslog.d/50-default.conf"
  echo -e " Using rsyslog config: ${blue}$RSYSLOG_FILE${neutral}"
elif [[ "$os_version" == "debian 12" ]]; then
  RSYSLOG_FILE="/etc/rsyslog.conf"
  echo -e " Using rsyslog config: ${blue}$RSYSLOG_FILE${neutral}"
else
  echo -e " ${red}Unsupported OS or version. Exiting...${neutral}"
  exit 1
fi

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}📝 CONFIGURING DROPBEAR LOGGING${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

# Menjalankan pengecekan dan penambahan konfigurasi jika diperlukan
if check_dropbear_log; then
  echo -e " Dropbear configuration already exists ${green}✓${neutral}"
else
  add_dropbear_log
  echo -e " Dropbear configuration added successfully ${green}✓${neutral}"
fi

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🔐 SETTING LOG FILE PERMISSIONS${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

set_permissions

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🧹 CLEANING UP INSTALLATION${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"

run_with_spinner "Removing installation script..." rm -f /root/setrsyslog.sh

echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${bold_white}🎉 RSYSLOG CONFIGURATION COMPLETED${neutral}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "${yellow}Configuration applied:${neutral}"
echo -e "${blue}• OS Detection: $os_version${neutral}"
echo -e "${blue}• Dropbear logging configured${neutral}"
echo -e "${blue}• Log file permissions set${neutral}"
echo -e "${blue}• Rsyslog service restarted${neutral}"
echo -e "${green}All rsyslog configurations have been applied successfully!${neutral}"
echo ""
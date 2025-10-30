#!/bin/bash

# Color definitions
BlueCyan='\e[1;36m'
Xark='\e[0m'
ungu='\033[0;35m'
yellow='\e[1;33m'
WhiteBe='\e[1;37m'
GreenBe='\e[1;32m'
red='\e[1;31m'
cyan='\e[1;36m'

# Nama developer tetap
nama="PeyxDev"

clear

# Function untuk animasi loading
function loading_animasi() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n "Loading "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

function loading_dots() {
    local text=$1
    echo -n "$text"
    for i in {1..3}; do
        sleep 0.5
        echo -n "."
    done
    echo
}

function baris_panjang() {
    echo -e "${BlueCyan}———————————————————————————————————————————${Xark}"
}

function tampilkan_developer() {
    baris_panjang
    echo -e "${GreenBe}           Developer: $nama ${Xark}"
    baris_panjang
}

function tampilkan_log_info() {
    echo -e "${cyan}"
    echo "Reinstalling System..."
    echo "To view logs run:"
    echo "tail -fn+1 /reinstall.log"
    echo -e "${Xark}"
}

# Function untuk clean rebuild
function clean_rebuild() {
    local os=$1
    local version=$2
    
    tampilkan_developer
    echo -e "${yellow}Starting Clean Rebuild...${Xark}"
    echo -e "${cyan}OS: $os $version${Xark}"
    baris_panjang
    
    # Step 1: Download reinstall script
    echo -e "${yellow}Step 1: Downloading reinstall script...${Xark}"
    (curl -s -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh) &
    loading_animasi $!
    echo -e "${GreenBe}✓ Download completed${Xark}"
    
    # Step 2: Create auto-install script untuk setelah rebuild
    echo -e "${yellow}Step 2: Preparing auto-installation...${Xark}"
    create_auto_install_script
    echo -e "${GreenBe}✓ Auto-install script prepared${Xark}"
    
    # Step 3: Execute rebuild
    echo -e "${yellow}Step 3: Starting system rebuild...${Xark}"
    loading_dots "Rebuilding system"
    tampilkan_log_info
    echo -e "${red}WARNING: System will reboot automatically${Xark}"
    echo -e "${yellow}Please wait...${Xark}"
    
    # Jalankan rebuild dengan auto reboot
    bash reinstall.sh $os $version
}

# Function untuk membuat auto install script
function create_auto_install_script() {
    cat > /root/peyx_auto_install.sh << 'EOF'
#!/bin/bash

# Auto Install Script by PeyxDev
echo "=== PeyxDev Auto Installation ==="
sleep 5

# Update system dan install dependencies
echo "Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget sudo nano htop net-tools

# Install basic services
echo "Installing basic services..."
apt-get install -y nginx cron bash-completion

# Download dan install main panel script
echo "Downloading panel installation script..."
wget -q -O /root/install_panel.sh https://raw.githubusercontent.com/peyxdev/scripts/main/install.sh
if [ -f /root/install_panel.sh ]; then
    chmod +x /root/install_panel.sh
    echo "Starting panel installation..."
    bash /root/install_panel.sh
else
    echo "Panel script not found, installing basic setup..."
    # Alternative basic setup
    wget -q -O /root/basic_setup.sh https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
    if [ -f /root/basic_setup.sh ]; then
        chmod +x /root/basic_setup.sh
    fi
fi

# Cleanup
echo "Cleaning up..."
rm -f /root/peyx_auto_install.sh
echo "=== Auto Installation Complete ==="
EOF

    chmod +x /root/peyx_auto_install.sh
    
    # Tambahkan ke crontab untuk dijalankan setelah boot
    (crontab -l 2>/dev/null; echo "@reboot /bin/bash /root/peyx_auto_install.sh") | crontab -
}

# Function untuk manual install setelah rebuild
function manual_install_menu() {
    echo -e "${yellow}"
    echo "After rebuild completes, you can manually install:"
    echo "1. Run: wget https://raw.githubusercontent.com/peyxdev/scripts/main/install.sh && bash install.sh"
    echo "2. Or use your preferred installation script"
    echo -e "${Xark}"
}

# Menu Ubuntu
function osx_ubuntu() {
    baris_panjang
    echo -e "${ungu}           Pilih OS Ubuntu      ${Xark}"
    baris_panjang
    echo -e "${ungu}"
    echo " 1. Ubuntu 20.04 LTS"
    echo " 2. Ubuntu 22.04 LTS" 
    echo " 3. Ubuntu 24.04 LTS"
    echo " 4. Ubuntu 25.10"
    echo -e "${Xark}"
    echo -e "${yellow} 0. Kembali ke Menu Utama${Xark}"
    echo -e "${yellow} x. Exit${Xark}"
    baris_panjang
    read -p "PeyxDev:~# Pilih [1-4/0/x] : " Xw
    case $Xw in
        1) clean_rebuild ubuntu 20.04 ;;
        2) clean_rebuild ubuntu 22.04 ;;
        3) clean_rebuild ubuntu 24.04 ;;
        4) clean_rebuild ubuntu 25.10 ;;
        0) main_menu ;;
        *) exit ;;
    esac
}

# Menu Debian
function osx_debian() {
    baris_panjang
    echo -e "${ungu}           Pilih OS Debian      ${Xark}"
    baris_panjang
    echo -e "${ungu}"
    echo " 1. Debian 11 (Bullseye)"
    echo " 2. Debian 12 (Bookworm)"
    echo -e "${Xark}"
    echo -e "${yellow} 0. Kembali ke Menu Utama${Xark}"
    echo -e "${yellow} x. Exit${Xark}"
    baris_panjang
    read -p "PeyxDev:~# Pilih [1-2/0/x] : " Xw
    case $Xw in
        1) clean_rebuild debian 11 ;;
        2) clean_rebuild debian 12 ;;
        0) main_menu ;;
        *) exit ;;
    esac
}

# Menu CentOS/Rocky
function osx_centos() {
    baris_panjang
    echo -e "${ungu}           Pilih OS CentOS/Rocky ${Xark}"
    baris_panjang
    echo -e "${ungu}"
    echo " 1. Rocky Linux 8"
    echo " 2. Rocky Linux 9"
    echo " 3. AlmaLinux 8"
    echo " 4. AlmaLinux 9"
    echo -e "${Xark}"
    echo -e "${yellow} 0. Kembali ke Menu Utama${Xark}"
    echo -e "${yellow} x. Exit${Xark}"
    baris_panjang
    read -p "PeyxDev:~# Pilih [1-4/0/x] : " Xw
    case $Xw in
        1) clean_rebuild rocky 8 ;;
        2) clean_rebuild rocky 9 ;;
        3) clean_rebuild almalinux 8 ;;
        4) clean_rebuild almalinux 9 ;;
        0) main_menu ;;
        *) exit ;;
    esac
}

# Banner utama
function Banner() {
    echo -e "${GreenBe}"
    cat << "EOF"
    ____                       __   ___     
   / __ \___  ____  ___  _____/ /__/   |___
  / /_/ / _ \/ __ \/ _ \/ ___/ //_/ /| <_ /
 / ____/  __/ / / /  __/ /  / ,< / ___ |/ / 
/_/    \___/_/ /_/\___/_/  /_/|_/_/  |_/_/  
EOF
    echo -e "${Xark}"
    baris_panjang
    echo -e "${ungu}           CLEAN VPS REBUILD SYSTEM${Xark}"
    baris_panjang
}

# Menu utama
function Main_Menu() {
    echo -e "${ungu}"
    echo " 1. Rebuild Ubuntu"
    echo " 2. Rebuild Debian" 
    echo " 3. Rebuild CentOS/Rocky/AlmaLinux"
    echo " 4. Manual Installation Guide"
    echo -e "${Xark}"
    echo -e "${yellow} x. Exit${Xark}"
    baris_panjang
}

# Manual guide
function show_manual_guide() {
    clear
    tampilkan_developer
    echo -e "${yellow}MANUAL INSTALLATION GUIDE${Xark}"
    baris_panjang
    echo -e "${cyan}"
    echo "After rebuild completes, run these commands:"
    echo ""
    echo "1. Update system:"
    echo "   apt update && apt upgrade -y"
    echo ""
    echo "2. Install dependencies:"
    echo "   apt install -y curl wget sudo"
    echo ""
    echo "3. Install panel script:"
    echo "   wget https://raw.githubusercontent.com/peyxdev/scripts/main/install.sh"
    echo "   bash install.sh"
    echo ""
    echo "4. Or use alternative script:"
    echo "   wget https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
    echo "   bash reinstall.sh"
    echo -e "${Xark}"
    baris_panjang
    read -p "Press Enter to return to main menu..." dummy
    main_menu
}

# Main menu function
function main_menu() {
    clear
    tampilkan_developer
    Banner
    Main_Menu
    read -p "PeyxDev:~# Pilih [1-4/x] : " Ltt
    case $Ltt in
        1) clear ; osx_ubuntu ;;
        2) clear ; osx_debian ;;
        3) clear ; osx_centos ;;
        4) clear ; show_manual_guide ;;
        *) exit ;;
    esac
}

# Start script
main_menu

#!/bin/bash

# Warna output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Fungsi untuk menampilkan pesan sukses
function success_message {
    echo -e "${GREEN}[✔] $1${NC}"
}

# Fungsi untuk menampilkan pesan proses
function info_message {
    echo -e "${CYAN}[-] $1...${NC}"
}

# Fungsi untuk menampilkan pesan kesalahan
function error_message {
    echo -e "${RED}[✘] $1${NC}"
}


# Fungsi untuk menampilkan pesan selamat datang
print_welcome_message() {
    echo -e "\033[1;37m"
    echo " _  _ _   _ ____ ____ _    ____ _ ____ ___  ____ ____ ___ "
    echo "|\\ |  \\_/  |__| |__/ |    |__| | |__/ |  \\ |__/ |  | |__]"
    echo "| \\|   |   |  | |  \\ |    |  | | |  \\ |__/ |  \\ |__| |    "
    echo -e "\033[1;32m"
    echo "Nyari Airdrop Auto install Privasea"
    echo -e "\033[1;33m"
    echo "Telegram: https://t.me/nyariairdrop"
    echo -e "\033[0m"
}

# Pembersihan layar
clear
print_welcome_message
echo -e "${CYAN}========================================"
echo "   Privasea Acceleration Node Setup"
echo -e "========================================${NC}"
echo ""

# Langkah 0: Pengecekan spesifikasi sistem
info_message "Memeriksa spesifikasi sistem"

CPU_CORES=$(nproc)
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
AVAILABLE_STORAGE=$(df -h / | awk '/\//{print $(NF-2)}')

info_message "Jumlah inti prosesor: $CPU_CORES"
info_message "Total RAM: ${TOTAL_RAM}MB"
info_message "Ruang penyimpanan tersedia: $AVAILABLE_STORAGE"

if [ "$CPU_CORES" -ge 16 ] && [ "$TOTAL_RAM" -ge 8192 ]; then
    CONFIG_LEVEL="Level 1"
elif [ "$CPU_CORES" -ge 8 ] && [ "$TOTAL_RAM" -ge 4096 ]; then
    CONFIG_LEVEL="Level 2"
elif [ "$CPU_CORES" -ge 4 ] && [ "$TOTAL_RAM" -ge 4096 ]; then
    CONFIG_LEVEL="Level 3"
elif [ "$CPU_CORES" -ge 2 ] && [ "$TOTAL_RAM" -le 4096 ]; then
    CONFIG_LEVEL="Level 4"
else
    error_message "Spesifikasi sistem tidak memenuhi persyaratan minimum."
    exit 1
fi

success_message "Sistem memenuhi persyaratan untuk $CONFIG_LEVEL"
echo ""

# Langkah 1: Pengecekan apakah Docker sudah terpasang
if ! command -v docker &> /dev/null
then
    info_message "Docker tidak ditemukan, memulai instalasi Docker..."
    sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update && sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker
    success_message "Docker berhasil diinstal dan dijalankan."
else
    success_message "Docker sudah terpasang. Lewati instalasi Docker."
fi

# Langkah 2: Pengecekan storage tersedia
AVAILABLE_STORAGE=$(df -h / | awk 'NR==2 {print $4}')
info_message "Storage yang tersedia: $AVAILABLE_STORAGE"

# Langkah 3: Membuka port jika belum terbuka
PORT=8181
if ! sudo ufw status | grep -qw "$PORT"; then
    info_message "Membuka port $PORT..."
    sudo ufw allow $PORT/tcp
    success_message "Port $PORT berhasil dibuka."
else
    success_message "Port $PORT sudah terbuka."
fi

# Langkah 4: Tarik gambar Docker
info_message "Mengunduh gambar Docker"
if docker pull privasea/acceleration-node-beta:latest; then
    success_message "Gambar Docker berhasil diunduh"
else
    error_message "Gagal mengunduh gambar Docker"
    exit 1
fi

# Langkah 5: Buat direktori konfigurasi
CONFIG_DIR="$HOME/privasea/config"
info_message "Membuat direktori konfigurasi di $CONFIG_DIR"
if mkdir -p "$CONFIG_DIR"; then
    success_message "Direktori konfigurasi berhasil dibuat"
else
    error_message "Gagal membuat direktori konfigurasi"
    exit 1
fi

# Langkah 6: Buat file keystore dan ambil node address
info_message "Membuat file keystore dan mengambil node address"
NODE_ADDRESS=$(docker run -it -v "$CONFIG_DIR:/app/config" \
privasea/acceleration-node-beta:latest ./node-calc new_keystore 2>&1 | \
grep -o '0x[0-9a-fA-F]\{40\}')
if [ -n "$NODE_ADDRESS" ]; then
    success_message "File keystore berhasil dibuat"
    success_message "Node address: $NODE_ADDRESS"
else
    error_message "Gagal membuat file keystore atau mengambil node address"
    exit 1
fi

# Langkah 7: Memindahkan file keystore ke nama baru
info_message "Memindahkan file keystore"
if mv $CONFIG_DIR/UTC--* $CONFIG_DIR/wallet_keystore; then
    success_message "File keystore berhasil dipindahkan ke wallet_keystore"
else
    error_message "Gagal memindahkan file keystore"
    exit 1
fi

# Langkah 8: Pilihan untuk melanjutkan atau tidak
read -p "Apakah Anda ingin melanjutkan untuk menjalankan node (y/n)? " choice
if [[ "$choice" != "y" ]]; then
    echo -e "${CYAN}Proses dibatalkan.${NC}"
    exit 0
fi

# Langkah 9: Meminta password untuk keystore
info_message "Masukkan password untuk keystore (untuk mengakses node):"
read -s KEYSTORE_PASSWORD
echo ""

# Langkah 10: Jalankan node
info_message "Menjalankan Privasea Acceleration Node"
if docker run -d -v "$CONFIG_DIR:/app/config" \
-e KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD \
privasea/acceleration-node-beta:latest; then
    success_message "Node berhasil dijalankan"
else
    error_message "Gagal menjalankan node"
    exit 1
fi

# Kesimpulan
echo -e "${GREEN}========================================"
echo "   Setup Selesai"
echo -e "========================================${NC}"
echo ""
echo -e "${CYAN}Informasi Penting:${NC}"
echo -e "${CYAN}- Node address:${NC} $NODE_ADDRESS"
echo -e "${CYAN}- Direktori konfigurasi:${NC} $CONFIG_DIR"
echo -e "${CYAN}- File keystore:${NC} wallet_keystore"
echo -e "${CYAN}- Password keystore:${NC} $KEYSTORE_PASSWORD"
echo -e "${CYAN}- Port yang digunakan:${NC} $PORT"
echo -e "${CYAN}- Storage yang tersedia:${NC} $AVAILABLE_STORAGE"
echo ""

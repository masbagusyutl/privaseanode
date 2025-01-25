#!/bin/bash

# Fungsi untuk menampilkan pesan berwarna
print_message() {
    COLOR=$1
    MESSAGE=$2
    echo -e "${COLOR}${MESSAGE}\033[0m"
}

# Fungsi untuk menampilkan pesan sukses
success_message() {
    print_message "\033[0;32m" "[✔] $1"
}

# Fungsi untuk menampilkan pesan informasi
info_message() {
    print_message "\033[0;36m" "[-] $1..."
}

# Fungsi untuk menampilkan pesan kesalahan
error_message() {
    print_message "\033[0;31m" "[✘] $1"
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
echo ""

# Langkah 1: Pengecekan spesifikasi sistem
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

# Langkah 2: Memastikan port 8181 terbuka
info_message "Memeriksa apakah port 8181 terbuka"

if ! sudo lsof -i:8181 > /dev/null; then
    info_message "Port 8181 tidak terbuka. Membuka port 8181..."
    sudo ufw allow 8181/tcp
    success_message "Port 8181 berhasil dibuka."
else
    success_message "Port 8181 sudah terbuka."
fi

echo ""

# Langkah 3: Pengecekan apakah Docker sudah terpasang
if ! command -v docker &> /dev/null; then
    info_message "Docker tidak ditemukan, memulai instalasi Docker..."
    sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker
    success_message "Docker berhasil diinstal dan dijalankan."
else
    success_message "Docker sudah terpasang. Lewati instalasi Docker."
fi

echo ""

# Langkah 4: Tarik gambar Docker
info_message "Mengunduh gambar Docker"
if docker pull privasea/acceleration-node-beta:latest; then
    success_message "Gambar Docker berhasil diunduh"
else
    error_message "Gagal mengunduh gambar Docker"
    exit 1
fi

echo ""

# Langkah 5: Buat direktori konfigurasi
info_message "Membuat direktori konfigurasi"
if mkdir -p $HOME/privasea/config; then
    success_message "Direktori konfigurasi berhasil dibuat"
else
    error_message "Gagal membuat direktori konfigurasi"
    exit 1
fi

echo ""

# Langkah 6: Buat file keystore
info_message "Membuat file keystore"
if docker run -it -v "$HOME/privasea/config:/app/config" \
privasea/acceleration-node-beta:latest ./node-calc new_keystore; then
    success_message "File keystore berhasil dibuat"
else
    error_message "Gagal membuat file keystore"
    exit 1
fi

echo ""

# Langkah 7: Pindahkan file keystore ke nama baru
info_message "Memindahkan file keystore"
if mv $HOME/privasea/config/UTC--* $HOME/privasea/config/wallet_keystore; then
    success_message "File keystore berhasil dipindahkan ke wallet_keystore"
else
    error_message "Gagal memindahkan file keystore"
    exit 1
fi

echo ""

# Langkah 8: Meminta password untuk keystore
info_message "Buat password keystore akses node:"
read -s KEystorePassword
echo ""

# Langkah 9: Jalankan node
info_message "Menjalankan Privasea Acceleration Node"
NODE_ID=$(docker run -d -v "$HOME/privasea/config:/app/config" \
-e KEYSTORE_PASSWORD=$KEystorePassword \
privasea/acceleration-node-beta:latest)

if [ $? -eq 0 ]; then
    success_message "Node berhasil dijalankan dengan ID $NODE_ID"
else
    error_message "Gagal menjalankan node"
    exit 1
fi

echo ""

# Kesimpulan
echo -e "\033[0;32m========================================"
echo "          Nyari Airdrop Auto install Privasea"
echo "          => Kesimpulan Proses <= "
echo -e "========================================\033[0m"
echo -e "\033[0;36mSpesifikasi VPS mu:"
echo "  - CPU Cores: $CPU_CORES"
echo "  - RAM: ${TOTAL_RAM}MB"
echo "  - Storage: $AVAILABLE_STORAGE"
echo "  - Konfigurasi Level yang bisa dilakukan: $CONFIG_LEVEL"
echo -e "\033[0;36mInformasi Penting:"
echo "  - File konfigurasi: $HOME/privasea/config"
echo "  - Keystore: wallet_keystore"
echo "  - Password Keystore: $KEystorePassword"
echo "  - Node ID: $(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $NODE_ID)"
echo "  - Jangan lupa masukkan node addres ke dasboard Privaseanya"
echo "  - untuk node addres ada"
echo "  - di bagian print proses membuat file keystore"
echo -e "========================================"

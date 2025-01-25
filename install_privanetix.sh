#!/bin/bash

# Fungsi untuk menampilkan welcome message
print_welcome_message() {
    echo -e "\033[1;37m"  # Warna putih untuk teks
    echo " _  _ _   _ ____ ____ _    ____ _ ____ ___  ____ ____ ___ "
    echo "|\\ |  \\_/  |__| |__/ |    |__| | |__/ |  \\ |__/ |  | |__]"
    echo "| \\|   |   |  | |  \\ |    |  | | |  \\ |__/ |  \\ |__| |       "
    echo -e "\033[1;32m"  # Warna hijau untuk teks terang
    echo "Nyari Airdrop Auto install Privasea"
    echo -e "\033[1;33m"  # Warna kuning untuk teks terang
    echo "Telegram: https://t.me/nyariairdrop"
    echo -e "\033[0m"  # Reset warna
}

# Menampilkan welcome message sebelum instalasi
print_welcome_message

# Fungsi untuk menampilkan informasi spesifikasi VPS
display_vps_info() {
    echo "🔍 Spesifikasi VPS yang digunakan:"
    echo "================================"
    echo "CPU: $(nproc) Core(s)"
    echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
    echo "Disk: $(df -h | grep '/$' | awk '{print $2}')"
    echo "OS: $(lsb_release -d | awk -F"\t" '{print $2}')"
    echo "================================"
}

# Fungsi untuk menentukan konfigurasi yang disarankan berdasarkan spesifikasi VPS
recommend_configuration() {
    cores=$(nproc)
    ram=$(free -h | grep Mem | awk '{print $2}' | sed 's/[^0-9]*//g')

    echo "⚙️ Menentukan konfigurasi yang disarankan berdasarkan spesifikasi VPS..."

    if [[ "$cores" -ge 16 && "$ram" -ge 8 ]]; then
        echo "📈 Level 1 (Rekomendasi Terbaik)"
        echo "OS: Debian/Ubuntu (Recommended)"
        echo "Storage: 100GB available"
        echo "Memory: 8GB RAM"
        echo "Processor: 16 cores"
        echo "Network: Public static IP"
        echo "Port: Open TCP port 8181"
        echo "==============================="
        cpu_limit="--cpus='8.0'"
    elif [[ "$cores" -ge 8 && "$ram" -ge 4 ]]; then
        echo "📈 Level 2"
        echo "OS: Debian/Ubuntu (Recommended)"
        echo "Storage: 100GB available"
        echo "Memory: 4GB RAM"
        echo "Processor: 8 cores"
        echo "Network: Public static IP"
        echo "Port: Open TCP port 8181"
        echo "==============================="
        cpu_limit="--cpus='4.0'"
    elif [[ "$cores" -ge 4 && "$ram" -ge 4 ]]; then
        echo "📊 Level 3"
        echo "OS: Debian/Ubuntu (Recommended)"
        echo "Storage: 100GB available"
        echo "Memory: 4GB RAM"
        echo "Processor: 4 cores"
        echo "Network: Public static IP"
        echo "Port: Open TCP port 8181"
        echo "==============================="
        cpu_limit="--cpus='2.0'"
    else
        echo "⚠️ Level 4"
        echo "OS: Debian/Ubuntu (Recommended)"
        echo "Storage: 100GB available"
        echo "Memory: 4GB RAM or below"
        echo "Processor: 2 cores or below"
        echo "Network: Public static IP"
        echo "Port: Open TCP port 8181"
        echo "==============================="
        cpu_limit="--cpus='1.0'"
    fi
}

# Fungsi untuk menginstal Docker jika belum terinstal
check_and_install_docker() {
    if ! command -v docker &> /dev/null
    then
        echo "🛑 Docker tidak ditemukan, menginstal Docker..."
        install_docker
    else
        echo "✅ Docker sudah terinstal, melanjutkan instalasi node..."
    fi
}

# Fungsi untuk instalasi Docker
install_docker() {
    sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update && sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker
}

# Fungsi untuk setup firewall
setup_firewall() {
    echo "🛡️ Mengatur firewall untuk membuka port 8181..."
    sudo ufw allow 8181/tcp
    sudo ufw enable
}

# Fungsi untuk membuat keystore wallet baru dengan password otomatis
create_keystore() {
    echo "🔑 Membuat keystore wallet baru..."
    mkdir -p /privasea/config

    # Cek apakah password sudah ada
    if [ ! -f "/privasea/config/password.txt" ]; then
        PASSWORD=$(openssl rand -base64 12)  # Generate password acak
        echo "$PASSWORD" > /privasea/config/password.txt
        chmod 600 /privasea/config/password.txt  # Lindungi file password
    else
        PASSWORD=$(cat /privasea/config/password.txt)
    fi

    echo "⚠️ Password keystore: $PASSWORD (tersimpan di /privasea/config/password.txt)"
    docker run -it -v "/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore <<< "$PASSWORD"
}

# Fungsi untuk menjalankan node dengan Docker
run_node() {
    echo "🚀 Menjalankan Privanetix Node..."
    docker pull privasea/acceleration-node-beta:latest
    docker run -d -p 8181:8181 $cpu_limit -v /privasea/config:/app/config privasea/acceleration-node-beta:latest
}

# Fungsi untuk menambahkan auto-restart saat VPS reboot
enable_autostart() {
    echo "🔄 Mengaktifkan auto-restart node..."
    (crontab -l 2>/dev/null; echo "@reboot docker run -d -p 8181:8181 $cpu_limit -v /privasea/config:/app/config privasea/acceleration-node-beta:latest") | crontab -
}

# Menjalankan fungsi
print_welcome_message
display_vps_info
recommend_configuration
check_and_install_docker
setup_firewall
create_keystore
run_node
enable_autostart

echo "✅ Instalasi selesai! Gunakan 'docker ps' untuk cek status node."

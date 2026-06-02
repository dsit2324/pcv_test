#!/bin/bash

set -e

### =========================
### CONFIG
### =========================
VM_NAME="ubuntu-srv"

USERNAME="admin"
PASSWORD="admin123"

RAM=2048
CPUS=2
DISK_SIZE=20000

ISO="/home/student/Stažené/ubuntu-24.04.3-live-server-amd64.iso"

SSH_PORT=2222

### =========================
### FIND ISO CHECK
### =========================
if [ ! -f "$ISO" ]; then
  echo "❌ ISO not found: $ISO"
  exit 1
fi

echo "📀 ISO: $ISO"

### =========================
### CLEANUP (SAFE + STABLE)
### =========================
echo "🧹 Cleanup..."

# kill possible locked processes
pkill -f VBoxHeadless 2>/dev/null || true
pkill -f VirtualBox 2>/dev/null || true

sleep 2

# remove VM if exists
VBoxManage controlvm "$VM_NAME" poweroff 2>/dev/null || true
VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true

# remove only files (NO VirtualBox registry touch)
rm -f "$HOME/$VM_NAME"*.vdi 2>/dev/null || true

### =========================
### UNIQUE DISK (CRITICAL FIX)
### =========================
DISK="$HOME/${VM_NAME}-$(date +%s).vdi"

### =========================
### CREATE VM
### =========================
echo "📦 Creating VM..."

VBoxManage createvm --name "$VM_NAME" --ostype Ubuntu_64 --register

VBoxManage modifyvm "$VM_NAME" \
  --memory $RAM \
  --cpus $CPUS \
  --nic1 nat \
  --graphicscontroller vmsvga \
  --vram 128 \
  --boot1 dvd \
  --boot2 disk

### =========================
### CREATE DISK
### =========================
VBoxManage createmedium disk \
  --filename "$DISK" \
  --size $DISK_SIZE

### =========================
### STORAGE CONTROLLER
### =========================
VBoxManage storagectl "$VM_NAME" \
  --name "SATA" \
  --add sata \
  --controller IntelAhci

### =========================
### ATTACH DISK
### =========================
VBoxManage storageattach "$VM_NAME" \
  --storagectl "SATA" \
  --port 0 \
  --device 0 \
  --type hdd \
  --medium "$DISK"

### =========================
### ATTACH ISO
### =========================
VBoxManage storageattach "$VM_NAME" \
  --storagectl "SATA" \
  --port 1 \
  --device 0 \
  --type dvddrive \
  --medium "$ISO"

### =========================
### START VM (GUI = no blinking issues)
### =========================
echo ""
echo "🚀 Starting VM (GUI mode)"
echo "👉 Install Ubuntu manually:"
echo "   user: $USERNAME"
echo "   pass: $PASSWORD"
echo ""

VBoxManage startvm "$VM_NAME" --type gui

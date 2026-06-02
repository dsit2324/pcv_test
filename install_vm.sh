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

SSH_PORT=2222

### =========================
### ISO AUTO FIND
### =========================
ISO_PATH=$(find ~ -type f -name "ubuntu-24.04*.iso" 2>/dev/null | head -n 1)

if [ -z "$ISO_PATH" ]; then
  echo "❌ ISO not found"
  exit 1
fi

echo "📀 ISO: $ISO_PATH"

### =========================
### SAFE CLEANUP (NO REGISTRY TOUCHING)
### =========================
echo "🧹 Cleanup..."

pkill -f VBoxHeadless 2>/dev/null || true
pkill -f VirtualBox 2>/dev/null || true

sleep 2

VBoxManage controlvm "$VM_NAME" poweroff 2>/dev/null || true
VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true

# IMPORTANT: only delete files, NOT VirtualBox registry
rm -f "$HOME/$VM_NAME"*.vdi 2>/dev/null || true

### =========================
### UNIQUE DISK (FIX FOR ALL UUID ERRORS)
### =========================
DISK_PATH="$HOME/${VM_NAME}-$(date +%s).vdi"

### =========================
### CREATE VM
### =========================
echo "📦 Creating VM..."

VBoxManage createvm --name "$VM_NAME" --ostype "Ubuntu_64" --register

VBoxManage modifyvm "$VM_NAME" \
  --memory $RAM \
  --cpus $CPUS \
  --nic1 nat \
  --natpf1 "ssh,tcp,127.0.0.1,$SSH_PORT,,22"

### =========================
### CREATE DISK
### =========================
VBoxManage createmedium disk \
  --filename "$DISK_PATH" \
  --size $DISK_SIZE

### =========================
### STORAGE CONTROLLER
### =========================
VBoxManage storagectl "$VM_NAME" \
  --name "SATA" \
  --add sata \
  --controller IntelAhci

### =========================
### ATTACH DISK FIRST
### =========================
VBoxManage storageattach "$VM_NAME" \
  --storagectl "SATA" \
  --port 0 \
  --device 0 \
  --type hdd \
  --medium "$DISK_PATH"

### =========================
### ATTACH ISO
### =========================
VBoxManage storageattach "$VM_NAME" \
  --storagectl "SATA" \
  --port 1 \
  --device 0 \
  --type dvddrive \
  --medium "$ISO_PATH"

### =========================
### UNATTENDED INSTALL (FIXED HOSTNAME)
### =========================
VBoxManage unattended install "$VM_NAME" \
  --iso="$ISO_PATH" \
  --user="$USERNAME" \
  --password="$PASSWORD" \
  --full-user-name="Admin User" \
  --hostname="${VM_NAME}.local" \
  --locale="en_US" \
  --time-zone="Europe/Prague" \
  --install-additions

### =========================
### START VM
### =========================
VBoxManage startvm "$VM_NAME" --type headless

echo ""
echo "✅ DONE"
echo "SSH: ssh $USERNAME@127.0.0.1 -p $SSH_PORT"

#!/bin/bash

# === 設定値 ===
VMID=9000
VMNAME="ubuntu24-cloud"
MEMORY=2048
STORAGE="working"
STORAGE_SIZE="10G"
IMAGE_PATH="/mnt/pve/working/template/iso/noble-server-cloudimg-amd64.img"
TARGET_STORAGE="local-lvm"

# === VM作成 ===
echo "VM ${VMID} (${VMNAME}) を作成します"
qm create ${VMID} --name ${VMNAME} --memory ${MEMORY} --net0 virtio,bridge=vmbr0

# === Cloud Imageをインポート ===
echo "Cloud Image をインポートします"
qm importdisk ${VMID} ${IMAGE_PATH} ${STORAGE}

# === scsi0 に割り当て ===
echo "ディスクを scsi0 に割り当て"
qm set ${VMID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-${VMID}-disk-0

# === ディスクサイズを拡張 ===
echo "ディスクサイズを拡張します"
qm resize ${VMID} scsi0 ${STORAGE_SIZE}

# === VMをテンプレートに変換 ===
echo "VMをテンプレート化"
qm template ${VMID}

# === ディスクを local-lvm に移動 ===
echo "ディスクを ${TARGET_STORAGE} に移動"
qm move_disk ${VMID} scsi0 ${TARGET_STORAGE} --delete

# === Cloud-init ISO ディスク追加 ===
echo "Cloud-init ディスクを追加"
qm set ${VMID} --ide2 ${TARGET_STORAGE}:cloudinit

# === 起動ディスクとコンソール設定 ===
qm set ${VMID} --boot c --bootdisk scsi0
qm set ${VMID} --serial0 socket --vga serial0

# === DNS設定（任意）===
qm set ${VMID} --nameserver 1.1.1.1 --searchdomain localdomain

echo "テンプレート ${VMNAME}（VMID: ${VMID}） 作成完了"

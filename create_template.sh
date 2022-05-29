#!/bin/bash
set -e

TEMPLATE_NAME="ubuntu-server-jammy"
TEMPLATE_ID=900

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

VM_CLOUDIMG_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"

# Cloudimage base variables
VM_CLOUDIMG_NAME=$(basename $VM_CLOUDIMG_URL)
VM_CLOUDIMG_FULL_PATH="/tmp/${VM_CLOUDIMG_NAME}"

# Download image
wget --show-progress -o /dev/null -O $VM_CLOUDIMG_FULL_PATH $VM_CLOUDIMG_URL

qm create $TEMPLATE_ID --name $TEMPLATE_NAME --cores 1 --memory 1024 -ostype l26
qm importdisk $TEMPLATE_ID $VM_CLOUDIMG_FULL_PATH local-lvm

# Attach the disk to scsi0 bus and set it as default boot option
qm set $TEMPLATE_ID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$TEMPLATE_ID-disk-0,discard=on 
qm set $TEMPLATE_ID --boot c --bootdisk scsi0

qm set $TEMPLATE_ID --ide2 local-lvm:cloudinit 
qm set $TEMPLATE_ID --serial0 socket --vga serial0

qm template $TEMPLATE_ID

# cleanup
rm -fv $VM_CLOUDIMG_FULL_PATH

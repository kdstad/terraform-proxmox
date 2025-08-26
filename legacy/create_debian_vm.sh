#!/bin/bash

set -e

# MIT License
#
# Copyright (c) 2024 Kasper Stad
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Script Basename
BASENAME=$(basename $0)

# Help meassage
function get_help()
{
    echo
    echo "Usage: $BASENAME <parameters> ..."
    echo
    echo "Parameters:"
    echo "    -b, --base              Base LVM thin to clone to the new vm (default: 1)"
    echo "    --bridge                Network Bridge to use for the VM (default: br0)"
    echo "    -c, --cores             CPU Cores that will be assigned to the VM (default: 1)"
    echo "    --disk-size             Size of the VM disk in GB (default: 10)"
    echo "    --domain                Domain for deployment (default: reddog.stad.one)"
    echo "    -h, --help              Show this help message."
    echo "    -m, --memory            Memory that will be allocated to the VM in MB (default: 2048)"
    echo "    -n, --name              (required) Name of the VM without spaces, dots and other ambiguous characters"
    echo "    --os-variant            OS Variant for the VM (default: debian11)"
    echo "    --pool                  Storage Pool to use for the VM (default: nvme)"
    echo "    --ssh-key               (required) SSH Public Key to be added to the VM"
    echo
    exit 1
}

# This script needs root permissions to run, check that
if [ "$EUID" -ne 0 ]; then
    echo -e "[$BASENAME]: \033[0;31mError: You must run this script as root\033[0m"
    exit 1
fi

# Get Help if you don't specify any arguments...
if [ ${#} -eq 0 ]; then
    get_help
fi

# Parse all parameters
while [ ${#} -gt 0 ]; do
    case "${1}" in
        -b|--base)
            VM_BASE=$2
            shift
            shift
            ;;
        --bridge)
            VM_NET_BRIDGE=$2
            shift
            shift
            ;;
        -c|--cores)
            VM_CORES=$2
            shift
            shift
            ;;
        --disk-size)
            VM_DISK_SIZE="$2"
            shift
            shift
            ;;
        --domain)
            VM_DOMAIN="$2"
            shift
            shift
            ;;
        -h|--help)
            get_help
            ;;
        -m|--memory)
            VM_MEMORY=$2
            shift
            shift
            ;;
        -n|--name)
            VM_NAME="$2"
            if [[ $VM_NAME == *['!'@#\$%^\&*()\_+\']* ]];then
                echo -e "[$BASENAME]: \033[0;31mError: Specified hostname is invalid\033[0m"
                exit 1
            fi
            shift
            shift
            ;;
        --os-variant)
            VM_OS_VARIANT=$2
            shift
            shift
            ;;
        --pool)
            VM_POOL=$2
            shift
            shift
            ;;
        --ssh-key)
            VM_SSH_KEY=$2
            shift
            shift
            ;;
        *)
            get_help
            ;;
    esac
done

# Default values if they wasn't defined as parameters
# CHANGE THESE VALUES AS NEEDED IF YOU LIKE!
VM_BASE=${VM_BASE:-"debian12"}
VM_CORES=${VM_CORES:-1}
VM_DISK_SIZE=${VM_DISK_SIZE:-10}
VM_DOMAIN=${VM_DOMAIN:-"cloud.local"}
VM_MEMORY=${VM_MEMORY:-2048}
VM_NET_BRIDGE=${VM_NET_BRIDGE:-"br0"}
VM_OS_VARIANT=${VM_OS_VARIANT:-"debian11"}
VM_POOL=${VM_POOL:-"vg"}
VM_SSH_KEY=${VM_SSH_KEY:-""}

# Get Help if you don't specify required parameters (yes I know I'm a little demanding ;) )...
if [[ -z $VM_NAME || -z $VM_SSH_KEY ]]; then
    get_help
fi

VM_CI_ROOT_PATH="/var/lib/libvirt/cloud-init"
VM_DIR_STORAGE_POOL_PATH="/var/lib/libvirt/images"

mkdir -p "${VM_CI_ROOT_PATH}/${VM_NAME}"

cat > "${VM_CI_ROOT_PATH}/${VM_NAME}/user-data" << EOF
#cloud-config
hostname: ${VM_NAME}
manage_etc_hosts: true
fqdn: ${VM_NAME}.${VM_DOMAIN}
package_upgrade: true
timezone: Europe/Copenhagen
chpasswd:
  expire: False
power_state:
  mode: reboot
users:
  - name: debian
    groups: [ adm, cdrom, dip, plugdev, lxd, sudo ]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
    ssh_authorized_keys:
      - ${VM_SSH_KEY}
packages:
  - htop
  - qemu-guest-agent
  - vim
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl restart qemu-guest-agent
EOF

touch "${VM_CI_ROOT_PATH}/${VM_NAME}/meta-data"

(cd "${VM_CI_ROOT_PATH}/${VM_NAME}" && genisoimage -output ${VM_DIR_STORAGE_POOL_PATH}/${VM_NAME}-ci.iso -volid cidata -joliet -rock user-data meta-data)

lvcreate -kn -n ${VM_NAME} -s ${VM_POOL}/${VM_BASE}
lvresize -L${VM_DISK_SIZE}G ${VM_POOL}/${VM_NAME}

virt-install --name ${VM_NAME} --import --os-variant ${VM_OS_VARIANT} --memory ${VM_MEMORY} --vcpu ${VM_CORES} --network bridge=${VM_NET_BRIDGE} \
    --graphics vnc --disk /dev/mapper/${VM_POOL}-${VM_NAME} --disk ${VM_DIR_STORAGE_POOL_PATH}/${VM_NAME}-ci.iso,readonly=on --noreboot --noautoconsole
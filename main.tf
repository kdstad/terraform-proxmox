terraform {
	required_version = ">= 0.13.0"
	required_providers {
		proxmox = {
			source = "telmate/proxmox"
			version = ">= 2.9.10"
		}
	}
}

variable "proxmox_api_url" {
	type = string
}

variable "proxmox_api_token_id" {
	type = string
}

variable "proxmox_api_token_secret" {
	type = string
}

variable "user_ssh_key" {
	type = string
}

provider "proxmox" {
	pm_api_url = var.proxmox_api_url
	pm_api_token_id = var.proxmox_api_token_id
	pm_api_token_secret = var.proxmox_api_token_secret
	pm_tls_insecure = true
}

data "template_file" "user_data" {

	for_each = local.virtual_machines

	template  = "${file("${path.module}/user_data.cfg")}"

	vars = {
		ssh_key = var.user_ssh_key
		hostname = each.key
	}
}

resource "local_file" "cloud_init_user_data" {

	for_each = local.virtual_machines

	content = data.template_file.user_data[each.key].rendered
	filename = "${var.proxmox_snippet_dir}/${each.key}.yml"

	file_permission = "0644"
	directory_permission = "0755"
}

resource "proxmox_vm_qemu" "virtual_machines" {

	for_each = local.virtual_machines

	name = each.key
	vmid = try(each.value.vmid, null)

	depends_on = [
		local_file.cloud_init_user_data
	]

	cicustom = "user=${var.proxmox_snippet_storage}:snippets/${each.key}.yml"

	os_type = "cloud-init"
	target_node = var.proxmox_node
	clone = var.proxmox_template_name
	
	cpu = try(each.value.cpu_type, "kvm64")
	sockets = try(each.value.sockets, 1)
	memory = try(each.value.memory, 2048)

	disk {
		size = each.value.disk_size
		type = "scsi"
		storage = try(each.value.disk_storage, var.proxmox_disk_storage)
		discard = "on"
	}

	network {
		model = "virtio"
		bridge = try(each.value.bridge, var.proxmox_network_bridge)
	}

	ipconfig0 = "ip=dhcp"

	dynamic "disk" {

		for_each = try(each.value.data_disks, [])

		content {
			size = disk.value
			type = "scsi"
			storage = try(each.value.disk_storage, var.proxmox_disk_storage)
			discard = "on"
		}
	}
}

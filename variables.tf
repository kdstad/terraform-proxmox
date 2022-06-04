locals {
	virtual_machines = {
		"server1" = { }
		"server1" = { disk_size = "20G", sockets = 2, memory = "2048", data_disks = [ "10G", "20GB" ] }
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

variable "proxmox_disk_storage" {
	default = "local-lvm"
}

variable "proxmox_network_bridge" {
	default = "vmbr0"
}

variable "proxmox_node" {
	default = "pve"
}

variable "proxmox_snippet_dir" {
	default = "/var/lib/vz/snippets"
}

variable "proxmox_snippet_storage" {
	default = "local"
}

variable "proxmox_template_name" {
	default = "ubuntu-server-jammy"
}

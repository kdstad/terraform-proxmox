variable "proxmox_api_url" {
	type = string
}

variable "proxmox_api_token_id" {
	type = string
}

variable "proxmox_api_token_secret" {
	type = string
}

variable "proxmox_node" {
	default = "pve1"
}

variable "proxmox_template_name" {
	default = "ubuntu-server-jammy"
}

locals {
	virtual_machines = {
		"server1" = { disk_size = "10G", sockets = 1, memory = "1024", data_disks = [] }
		"server1" = { disk_size = "20G", sockets = 2, memory = "2048", data_disks = [ "10G", "20GB" ] }
	}
}

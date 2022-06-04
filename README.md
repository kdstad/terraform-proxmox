# terraform-proxmox

This repo contains the Terraform files for Proxmox.

## Usage

* Paste your private key for SSH in **id_rsa.pub**
* Update **credentials.auto.tfvars** with the proxmox API key and endpoint
* Create the template VM (eg. use create_template.sh directly on the server)
* define the Virtual Machines in *variables.tf* - remember to change the node name...

### virtual_machines arguments

* disk_size: The size of the root disk (default: 10G)
* sockets: Number of CPU sockets (default: 1)
* memory: Size of the RAM for the VM (default: 1024)
* data_disks: List of ekstra disks size

*Eksampel:*

```
"vm1" = { disk_size = "20G", sockets = 2, memory = "2048", data_disks = [ "10G", "20GB" ] }
```

## legacy/proxmox.sh

This is a older script from before I started using Terraform

## License

MIT License

Copyright (c) 2022 Kasper Stad

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

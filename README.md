# Proxmox VM Module

This Terraform module creates and configures a virtual machine in Proxmox VE using the bpg/proxmox provider. It supports cloud-init initialization, multiple network interfaces, additional disks, and hardware configuration.

## Features

- VM creation from Proxmox templates
- Cloud-init support for automated configuration
- Multiple network interfaces with VLAN support
- Additional disk attachments
- Hardware configuration (CPU, memory, storage)
- Cloud-init file management

## Usage

```hcl
module "example_server" {
  source = "./modules/proxmox-vm"

  vm_name     = "example-server"
  node_name   = "proxmox-node-01"
  vm_id       = 200
  template_id = proxmox_virtual_environment_vm.alma9_template.vm_id

  user_data = <<-EOT
#cloud-config

hostname: example-server.domain.com

packages:
 - qemu-guest-agent

users:
  - name: ansible
    groups: wheel
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample_ansible_key_here
    lock_passwd: true
    homedir: /home/ansible

  - name: root
    hashed_passwd: $6$rounds=4096$saltsalt$hashed_password_here
    lock_passwd: false
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample_root_key_here

runcmd:
 - [ /usr/sbin/setenforce, 0 ]
 - [ sed, -i, "s/SELINUX=enforcing/SELINUX=disabled/", /etc/sysconfig/selinux ]
 - [ systemctl, enable, --now, --no-block, qemu-guest-agent ]
 - [ dnf, update, -y ]
EOT

  primary_network = {
    address = "10.151.1.200"
    gateway = "10.151.1.1"
    cidr    = 24
    vlan    = 0
  }

  hardware = {
    disk_size = 60
    memory    = 8192
    cpu_cores = 4
    storage   = "local-lvm"
  }

  additional_disks = [
    {
      size      = 100
      interface = "virtio1"
      type      = "disk"
      backup    = true
    }
  ]

  additional_networks = [
    {
      bridge     = "vmbr1"
      vlan       = 100
      ip_address = "192.168.100.200"
      cidr       = 24
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| proxmox | ~> 0.81.0 |

## Providers

| Name | Version |
|------|---------|
| proxmox | ~> 0.81.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vm_name | Name of the VM | `string` | n/a | yes |
| node_name | Name of the Proxmox node | `string` | n/a | yes |
| vm_id | VM ID | `number` | n/a | yes |
| template_id | Template VM ID to clone from | `string` | n/a | yes |
| hardware | Hardware configuration | `object({disk_size=number, memory=number, cpu_cores=number, storage=string})` | n/a | yes |
| user_data | Cloud-init user data configuration | `string` | `null` | no |
| cloud_init_datastore | Datastore for cloud-init files | `string` | `"local"` | no |
| primary_network | Primary network IP configuration | `object({address=string, gateway=string, cidr=number, vlan=optional(number), bridge=optional(string), model=optional(string), firewall=optional(bool), enabled=optional(bool)})` | `null` | no |
| additional_networks | Additional network interfaces | `list(object({bridge=string, vlan=optional(number), ip_address=optional(string), cidr=optional(number), enabled=optional(bool), firewall=optional(bool), model=optional(string)}))` | `[]` | no |
| additional_disks | Additional disks to attach | `list(object({size=number, backup=optional(bool), type=string, interface=string, datastore_id=optional(string), file_format=optional(string)}))` | `[]` | no |
| cpu_type | CPU type for the VM | `string` | `"x86-64-v4"` | no |
| cpu_sockets | Number of CPU sockets | `number` | `1` | no |
| os_type | Operating system type | `string` | `"l26"` | no |

## Outputs

| Name | Description |
|------|-------------|
| vm | Created VM resource |
| primary_ip | Primary IPv4 address of the VM |

## Notes

- The module automatically handles cloud-init file creation and management
- Network configuration is managed by Proxmox rather than cloud-init network sections
- The VM lifecycle ignores changes to initialization and clone blocks to prevent unnecessary recreations
- QEMU guest agent is automatically enabled

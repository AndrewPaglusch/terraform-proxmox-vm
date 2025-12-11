
resource "proxmox_virtual_environment_file" "cloud_init" {
  count        = var.user_data != null ? 1 : 0
  content_type = "snippets"
  datastore_id = var.cloud_init_datastore
  node_name    = var.node_name

  source_raw {
    data      = var.user_data
    file_name = "${replace(var.vm_name, ".", "-")}-cloudinit.yml"
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.vm_name
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = "Managed by Terraform"

  clone {
    datastore_id = var.hardware.storage
    vm_id        = var.template_id
    node_name    = var.node_name
  }

  dynamic "initialization" {
    for_each = var.user_data != null ? [1] : []
    content {
      datastore_id      = var.hardware.storage
      user_data_file_id = proxmox_virtual_environment_file.cloud_init[0].id

      # Network configuration is handled by Proxmox, rather than CloudInit network sections.
      # Proxmox generates the CloudInit network configuration automatically based on the ip_config blocks,
      # which maps to network_device blocks by order (first ip_config -> first network_device, second -> second, etc.)

      # PRIMARY INTERFACE - IP CONFIG
      dynamic "ip_config" {
        for_each = var.primary_network != null ? [1] : []
        content {
          ipv4 {
            address = "${var.primary_network.address}/${var.primary_network.cidr}"
            gateway = var.primary_network.gateway
          }
          dynamic "ipv6" {
            for_each = var.enable_ipv6 ? [1] : []
            content {
              address = "auto"
            }
          }
        }
      }

      # ADDITIONAL INTERFACES - IP CONFIG
      dynamic "ip_config" {
        for_each = var.additional_networks
        content {
          ipv4 {
            address = ip_config.value.ip_address != null ? "${ip_config.value.ip_address}/${ip_config.value.cidr}" : "dhcp"
          }
        }
      }
    }
  }

  cpu {
    cores   = var.hardware.cpu_cores
    sockets = var.cpu_sockets
    type    = var.cpu_type
  }

  memory {
    dedicated = var.hardware.memory
  }

  disk {
    datastore_id = var.hardware.storage
    interface    = "virtio0"
    size         = var.hardware.disk_size
  }

  dynamic "disk" {
    for_each = var.additional_disks
    content {
      datastore_id = disk.value.datastore_id != null ? disk.value.datastore_id : var.hardware.storage
      file_format  = disk.value.file_format
      interface    = disk.value.interface
      size         = disk.value.size
      backup       = disk.value.backup
    }
  }

  # PRIMARY INTERFACE - HARDWARE CONFIG
  network_device {
    bridge   = var.primary_network.bridge
    vlan_id  = var.primary_network.vlan
    enabled  = var.primary_network.enabled
    firewall = var.primary_network.firewall
    model    = var.primary_network.model
  }

  # ADDITIONAL INTERFACES - HARDWARE CONFIG
  dynamic "network_device" {
    for_each = var.additional_networks
    content {
      bridge   = network_device.value.bridge
      vlan_id  = network_device.value.vlan
      enabled  = network_device.value.enabled
      firewall = network_device.value.firewall
      model    = network_device.value.model
    }
  }

  operating_system {
    type = var.os_type
  }

  agent {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      initialization,
      clone
    ]
  }
}

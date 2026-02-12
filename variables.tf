variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "node_name" {
  description = "Name of the Proxmox node"
  type        = string
}

variable "vm_id" {
  description = "VM ID"
  type        = number
}

# TODO: Add agent_enabled var like Windows module has

variable "template_id" {
  description = "Template VM ID to clone from"
  type        = string
}

variable "user_data" {
  description = "Cloud-init user data configuration"
  type        = string
  default     = null
}

variable "cloud_init_datastore" {
  description = "Datastore for cloud-init files"
  type        = string
  default     = "local"
}

variable "hardware" {
  description = "Hardware configuration"
  type = object({
    disk_size = number
    memory    = number
    cpu_cores = number
    storage   = string
  })
}

variable "additional_disks" {
  description = "Additional disks to attach"
  type = list(object({
    size         = number
    backup       = optional(bool, true)
    type         = string
    interface    = string
    datastore_id = optional(string)
    file_format  = optional(string, "raw")
  }))
  default = []
}

variable "cpu_type" {
  description = "CPU type for the VM"
  type        = string
  default     = "x86-64-v4"
}

variable "cpu_sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "l26"
}

variable "primary_network" {
  description = "Primary network IP configuration (null for no static IP)"
  type = object({
    address  = string
    gateway  = string
    cidr     = number
    vlan     = optional(number, 0)
    bridge   = optional(string, "vmbr0")
    model    = optional(string, "virtio")
    firewall = optional(bool, false)
    enabled  = optional(bool, true)
  })
  default = null
}

variable "enable_ipv6" {
  description = "Enable IPv6 with SLAAC (auto configuration)"
  type        = bool
  default     = false
}

variable "additional_networks" {
  description = "Additional network interfaces for bridge communication"
  type = list(object({
    bridge     = string
    vlan       = optional(number)
    ip_address = optional(string)
    cidr       = optional(number, 24)
    enabled    = optional(bool, true)
    firewall   = optional(bool, false)
    model      = optional(string, "virtio")
  }))
  default = []
}

variable "hotplug" {
  description = "Selectively enable hotplug features. Set to a list of features (disk, network, usb, memory, cpu), or use the default of all enabled. Set to [] to disable."
  type        = list(string)
  default     = ["disk", "network", "usb", "memory", "cpu"]

  validation {
    condition     = alltrue([for f in var.hotplug : contains(["disk", "network", "usb", "memory", "cpu"], f)])
    error_message = "Valid hotplug features are: disk, network, usb, memory, cpu."
  }
}

variable "numa" {
  description = "Enable NUMA. Automatically forced on when hotplug includes cpu or memory."
  type        = bool
  default     = false
}

variable "ipv6_ula_prefix_filter" {
  description = "Optional prefix filter for selecting ULA IPv6 address (e.g., 'fd97:cafe'). If not specified, returns the first ULA address found."
  type        = string
  default     = null
}


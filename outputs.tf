output "vm" {
  description = "Created VM resource"
  value       = proxmox_virtual_environment_vm.vm
}

output "primary_ip" {
  description = "Primary IPv4 address of the VM"
  value       = var.primary_network.address
}

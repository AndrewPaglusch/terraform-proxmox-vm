output "vm" {
  description = "Created VM resource"
  value       = proxmox_virtual_environment_vm.vm
}

output "primary_ip" {
  description = "Primary IPv4 address of the VM"
  value       = var.primary_network.address
}

output "ula_ipv6_address" {
  description = "ULA IPv6 address (fd00::/8 range)"
  value = try(
    flatten([
      for addr_list in proxmox_virtual_environment_vm.vm.ipv6_addresses : [
        for addr in addr_list : addr
        if length(regexall("^fd[0-9a-f]{2}:", addr)) > 0 && (
          var.ipv6_ula_prefix_filter == null ||
          startswith(addr, var.ipv6_ula_prefix_filter)
        )
      ]
    ])[0],
    null
  )
}

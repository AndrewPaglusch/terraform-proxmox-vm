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
        if length(regexall(var.ipv6_ula_match_pattern, addr)) > 0
      ]
    ])[0],
    null
  )
}

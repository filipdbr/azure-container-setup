# file defines the values that will be printed after terraform apply

output "public_ip_address" {
  description = "The public IP address of the Immich server"
  value       = azurerm_linux_virtual_machine.immich_vm.public_ip_address
}

output "immich_url" {
  description = "The URL to access the Immich web interface"
  value       = "http://${azurerm_linux_virtual_machine.immich_vm.public_ip_address}:80"
}

output "keyvault_name" {
  value = azurerm_key_vault.immich_kv.name
}
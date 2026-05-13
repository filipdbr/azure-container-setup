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

# after apply we can use terrform output -json azure_cred to get a JSON needed for github actions 
output "azure_cred" {
  sensitive = true
  value = {
    clientId       = azuread_application.github_actions.client_id
    clientSecret   = azuread_service_principal_password.github_actions_pw.value
    subscriptionId = data.azurerm_subscription.current.subscription_id
    tenantId       = data.azurerm_client_config.current.tenant_id
  }
}
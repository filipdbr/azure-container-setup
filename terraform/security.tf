# get the configuration of the current Azure provider (tenant ID etc.)
data "azurerm_client_config" "current" {}

# create azure key vault
resource "azurerm_key_vault" "immich_kv" {
  name                        = "immich-keyvault-${random_id.my_kv_id.hex}" # random ID: 4 bytes in hex format
  location                    = azurerm_resource_group.immich_rg.location
  resource_group_name         = azurerm_resource_group.immich_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7     # min length in Azure - soft delete of 7 days
  purge_protection_enabled    = false # disable purge protection for lab purposes

  sku_name = "standard"

  # access policy for the admin, full priveleges
  access_policy {
    object_id          = data.azurerm_client_config.current.object_id
    tenant_id          = data.azurerm_client_config.current.tenant_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }
}

# access policy for the VM (managed identity)
# grant only get permission in order to get the pwd
resource "azurerm_key_vault_access_policy" "vm_access_policy" {
  key_vault_id       = azurerm_key_vault.immich_kv.id
  object_id          = azurerm_linux_virtual_machine.immich_vm.identity[0].principal_id # managed identity
  tenant_id          = data.azurerm_client_config.current.tenant_id
  secret_permissions = ["Get"]
}

resource "azurerm_role_assignment" "vm_reader" {
  scope                = azurerm_resource_group.immich_rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_linux_virtual_machine.immich_vm.identity[0].principal_id
}

# helpers

# helper resource creating a random id of 4 bytes length
resource "random_id" "my_kv_id" {
  byte_length = 4
}

# generate a random pass to the db
resource "random_password" "db_pass_generator" {
  length  = 30
  special = false # as per immich documentation pwd shouldn't contain any special characters
}

# save the pwd to the key vault
resource "azurerm_key_vault_secret" "immich_db_pass" {
  name         = "immich-db-pass"
  value        = random_password.db_pass_generator.result
  key_vault_id = azurerm_key_vault.immich_kv.id
}

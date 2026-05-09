# create azure container registry to store docker image of immich
resource "azurerm_container_registry" "immich_acr" {
  name                = "immichcontainerregistry${random_id.my_kv_id.hex}" # using the same random id as generated in security.tf file
  resource_group_name = azurerm_resource_group.immich_rg.name
  location            = azurerm_resource_group.immich_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

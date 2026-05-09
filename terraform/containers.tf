# create azure container registry to store docker image of immich
resource "azurerm_container_registry" "immich_acr" {
  name = "immich-container-registry"
  resource_group_name = azurerm_resource_group.immich_rg.name
  location = azurerm_resource_group.immich_rg.location
  sku = "Basic"
  admin_enabled = true
}

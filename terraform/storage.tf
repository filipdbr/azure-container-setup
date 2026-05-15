# file will create the file share being a persistent storage for immich
resource "azurerm_storage_account" "immich_storage_acc" {
  name                     = "immich-storage-account"
  resource_group_name      = azurerm_resource_group.immich_rg.name
  location                 = azurerm_resource_group.immich_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # choosing the cheapest option as it's a lab
}

resource "azurerm_storage_share" "immich_file_share" {
  name               = "immich-storage-share"
  storage_account_id = azurerm_storage_account.immich_storage_acc.id
  quota              = 5 # small size (5 GB) as it's for a lab only
}

# Compute layer: Virtual Machine and Network Interface definition

# create a VM
resource "azurerm_linux_virtual_machine" "immich_vm" {
  name                = "immich-server"
  resource_group_name = azurerm_resource_group.immich_rg.name
  location            = azurerm_resource_group.immich_rg.location
  size                = var.vm_size
  admin_username      = var.admin_username

  # associate the network interface with the VM
  network_interface_ids = [
    azurerm_network_interface.immich_nic.id,
  ]

  # assign managed identity to a VM in order to get passwords from Azure Key Vault
  # using system-managed assigned identit
  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.disk_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = var.vm_sku
    version   = "latest"
  }

  # lauch a script installing docker on the immich server
  user_data = base64encode(templatefile("${path.module}/scripts/provision.sh", {
    # add variables
    pass_name  = azurerm_key_vault_secret.immich_db_pass.name
    vault_name = azurerm_key_vault.immich_kv.name
    admin_name = var.admin_username
  }))
}
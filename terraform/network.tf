# Network layer: VNet, Subnet, Public IP and Security Rules (Firewall)

# create a virtual network
resource "azurerm_virtual_network" "immich_vnet" {
  name                = "immich-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.immich_rg.location
  resource_group_name = azurerm_resource_group.immich_rg.name
}

# create a subnet
resource "azurerm_subnet" "immich_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.immich_rg.name
  virtual_network_name = azurerm_virtual_network.immich_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# public IP
resource "azurerm_public_ip" "immich_pip" {
  name                = "immich-public-ip"
  resource_group_name = azurerm_resource_group.immich_rg.name
  location            = azurerm_resource_group.immich_rg.location
  allocation_method   = "Dynamic"
}

# create a firewall
resource "azurerm_network_security_group" "immich_nsg" {
  name                = "immich-nsg"
  location            = azurerm_resource_group.immich_rg.location
  resource_group_name = azurerm_resource_group.immich_rg.name

  # allow ssh for admin connection
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # allow 2283 tcp port for access to the app (default immich port)
  security_rule {
    name                       = "Immich"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.immich_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# create network interface
resource "azurerm_network_interface" "immich_nic" {
  name                = "immich-nic"
  location            = azurerm_resource_group.immich_rg.location
  resource_group_name = azurerm_resource_group.immich_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.immich_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.immich_pip.id
  }
}

# associate NSG with the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.immich_nic.id
  network_security_group_id = azurerm_network_security_group.immich_nsg.id
}
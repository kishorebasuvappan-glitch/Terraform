resource "azurerm_resource_group" "rg"{

      name = var.resource_group_name
      location = var.location
}

resource "azurerm_virtual_network" "vnet" {

    name = var.virtual_network_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space = ["10.2.0.0/16"]
}

resource "azurerm_subnet_network" "subnet" {
    name = var.subnet_name
    location = azurerm_virtual_network.vnet.location
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.1.0.3/24"]
}
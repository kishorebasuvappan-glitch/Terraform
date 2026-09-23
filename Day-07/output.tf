output "RG_name" {
    description = "name of the rg"
    value = azurerm_resource_group.rg.name
}

output "Vnet_name" {
    description = "name of the Vnet"
    value = azurerm_virtual_network.vnet.name
}
resource "azurerm_resource_group" "rg"{
    name = each.value
    location = var.location
}
resource "azurerm_resource_group" "rg"{
    for_each = toset(var.resource_group_name)
    name = each.value
    location = var.location
}
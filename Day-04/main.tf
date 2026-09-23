resource "azurerm_resource_group" "rg"{
    for.each = var.resource_group_name
    name = each.value
    location = var.location
}
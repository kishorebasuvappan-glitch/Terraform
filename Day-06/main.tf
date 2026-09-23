resource "azurerm_resource_group" "rg"{
    for_each = var.resource_group_name
    name = each.value.resource_group_name
    location = each.value.location
}
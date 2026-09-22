resource "azurerm_resource_group" "rg" {
  count    = length(var.resource_group_name)
  name     = var.resource_group_name[count.index]
  location = var.location
}

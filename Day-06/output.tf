output "name" {
  description = "Names of the resource groups"
  value = {
    for key, rg in azurerm_resource_group.rg : key => rg.name
  }
}

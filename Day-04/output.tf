output "name" {
    description = "name of the rg"
    value = [for r in azurerm_resource_group.rg: r.name]
}
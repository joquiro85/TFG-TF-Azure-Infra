output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
output "name_servers" {
  value = azurerm_dns_zone.tfg_zone.name_servers
}

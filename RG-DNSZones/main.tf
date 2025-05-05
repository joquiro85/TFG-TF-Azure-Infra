#RG-DNSZones/main.tf
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_dns_zone" "tfg_zone" {
  name                = "tfg-joqr.es"
  resource_group_name = azurerm_resource_group.main.name

  lifecycle {
    prevent_destroy = true
  }
}

output "resource_group_name" {
  description = "Nombre del Resource Group"
  value       = data.azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Región del Resource Group"
  value       = data.azurerm_resource_group.main.location
}

output "load_balancer_public_ip" {
  description = "IP pública del Load Balancer"
  value       = azurerm_public_ip.lb_ip.ip_address
}

output "dns_zone_name" {
  description = "Nombre de la zona DNS"
  value       = data.azurerm_dns_zone.tfg_zone.name
}

output "root_record_fqdn" {
  description = "FQDN del registro raíz (@)"
  value       = azurerm_dns_a_record.tfg_root.fqdn
}

output "www_cname" {
  description = "CNAME para www"
  value       = azurerm_dns_cname_record.tfg_www.fqdn
}

output "jumpbox_public_ip" {
  description = "IP pública de la jumpbox"
  value       = azurerm_public_ip.vm_public_ip.ip_address
}

output "vmss_id" {
  description = "ID del Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.nginx_vmss.id
}

output "nat_gateway_public_ip" {
  description = "IP pública asignada al NAT Gateway"
  value       = azurerm_public_ip.nat_ip.ip_address
}

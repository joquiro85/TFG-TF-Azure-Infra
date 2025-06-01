#infra/main.tf
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_dns_zone" "tfg_zone" {
  name                = "tfg-joqr.es"
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "main" {
  name                = "tfg-vnet"
  address_space       = var.vnet_address_space
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_public_ip" "nat_ip" {
  name                = "tfg-nat-ip"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  name                    = "tfg-nat"
  location                = var.location
  resource_group_name     = data.azurerm_resource_group.main.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "nat_ip" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_ip.id
}

resource "azurerm_subnet" "public_1" {
  name                 = "public-subnet-1"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_cidr_1]
}

resource "azurerm_subnet" "private_1" {
  name                 = "private-subnet-1"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet_cidr_1]
}

resource "azurerm_subnet_nat_gateway_association" "private_1_nat" {
  subnet_id      = azurerm_subnet.private_1.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

resource "azurerm_public_ip" "lb_ip" {
  name                = "tfg-lb-ip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "tfg_lb" {
  name                = "tfg-lb"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend" {
  loadbalancer_id = azurerm_lb.tfg_lb.id
  name            = "BackendPool"
}

resource "azurerm_lb_probe" "http" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.tfg_lb.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.tfg_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend.id]
  probe_id                       = azurerm_lb_probe.http.id
  load_distribution              = "default"
}

resource "azurerm_network_security_group" "jumpbox_nsg" {
  name                = "nsg-jumpbox"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-SSH-Jumpbox"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "0.0.0.0/32" # no IP valida.
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-All-Outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "web_nsg" {
  name                = "nsg-web"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-All-Outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "tfg-vm-nic"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "tfg-vm-public-ip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface_security_group_association" "jumpbox_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.jumpbox_nsg.id
}


resource "azurerm_linux_virtual_machine_scale_set" "nginx_vmss" {
  name                            = "tfg-nginx-vmss"
  location                        = data.azurerm_resource_group.main.location
  resource_group_name             = data.azurerm_resource_group.main.name
  sku                             = var.vm_size
  instances                       = 2
  admin_username                  = var.vm_username
  admin_password                  = var.vm_password
  disable_password_authentication = false
  zones                           = [var.availability_zone_1]

  source_image_reference {
    publisher = var.image_reference.publisher
    offer     = var.image_reference.offer
    sku       = var.image_reference.sku
    version   = var.image_reference.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  upgrade_mode = "Manual"

  network_interface {
    name                      = "nginx-vmss-nic"
    network_security_group_id = azurerm_network_security_group.web_nsg.id
    primary                   = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.private_1.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_backend.id]
    }
  }

  custom_data = filebase64("${path.module}/user_data.sh")

  depends_on = [azurerm_network_interface_security_group_association.jumpbox_nic_nsg]
}

resource "azurerm_monitor_autoscale_setting" "nginx_vmss_autoscale" {
  name                = "autoscale-nginx"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.nginx_vmss.id
  enabled             = true

  profile {
    name = "default"

    capacity {
      minimum = "2"
      maximum = "4"
      default = "2"
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.nginx_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.nginx_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                            = "tfg-jumpbox"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  size                            = "Standard_B1s"
  admin_username                  = var.jumpusername
  admin_password                  = var.jumpuserpassword
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.vm_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_reference.publisher
    offer     = var.image_reference.offer
    sku       = var.image_reference.sku
    version   = var.image_reference.version
  }

  depends_on = [azurerm_network_interface_security_group_association.jumpbox_nic_nsg]

}

resource "azurerm_dns_a_record" "tfg_root" {
  name                = "@"
  zone_name           = data.azurerm_dns_zone.tfg_zone.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 300
  records             = [azurerm_public_ip.lb_ip.ip_address]
}

resource "azurerm_dns_cname_record" "tfg_www" {
  name                = "www"
  zone_name           = data.azurerm_dns_zone.tfg_zone.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 300
  record              = azurerm_dns_a_record.tfg_root.fqdn
}

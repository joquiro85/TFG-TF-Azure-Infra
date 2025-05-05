#variables provider
variable "client_id" {
  description = "Azure Client ID (Application ID)"
  type        = string
}

variable "client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# infrastructure variables
variable "resource_group_name" {
  type    = string
  default = "TFG-Infra"
}
variable "location" {
  description = "Azure region"
  default     = "West US 2"
}

variable "vm_size" {
  description = "Size of the Azure VM"
  default     = "Standard_B2s"
}

variable "image_reference" {
  description = "Image reference for Azure VM"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  default     = ["10.0.0.0/16"]
}

variable "public_subnet_cidr_1" {
  description = "CIDR block for public subnet 1"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr_1" {
  description = "CIDR block for private subnet 1"
  default     = "10.0.3.0/24"
}

variable "availability_zone_1" {
  description = "Availability zone 1"
  default     = "1"
}

variable "jumpusername" {
  description = "Jumpbox username"
  type        = string
  
}

variable "jumpuserpassword" {
  description = "Jumpbox password"
  type        = string
  sensitive   = true
  
}

variable "vm_username" {
  description = "VM username"
  type        = string
  
}

variable "vm_password" {
  description = "VM password"
  type        = string
  sensitive   = true
  
}
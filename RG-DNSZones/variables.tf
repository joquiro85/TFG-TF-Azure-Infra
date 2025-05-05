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
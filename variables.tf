# Subscription IDs
variable "ManagementSubscriptionID" {
  type        = string
  description = "This is the subscriptionID to use to connect to AzureRM."
}

variable "connectivitySubscriptionID" {
  type        = string
  description = "This is the subscriptionID to use to connect to AzureRM."
  
}

variable "landingzonecorpSubscriptionID" {
  type        = string
  description = "This is the subscriptionID to use to connect to AzureRM."
  
}

variable "landingzoneavdSubscriptionID" {
  type        = string
  description = "This is the subscriptionID to use to connect to AzureRM."
  
}

variable "enableresource" {
  type        = bool
  description = "This is to enable the PaaS resource provisioning."
  
}

variable "enablevms" {  
  type        = bool
  description = "This is to enable the VMs resource provisioning"
  
}
variable "vpnsharedkey" {
  type        = string
  description = "This is the VPN Shared Keys."
  
}
variable "vm_admin_password" {
  type        = string
  description = "This is the VM admin password."
  
}

variable "administrator_sql_login_password" {
  type        = string
  description = "This is the SQL Admin password."
  
}

variable "avdenabled" {
  type        = bool
  description = "Enable or disable the deployment of AVD resources."
  default     = true
}

variable "onpremises" {
  type        = bool
  description = "Enable or disable the deployment of on-premises resources and VPN gateway."
  default     = true
}
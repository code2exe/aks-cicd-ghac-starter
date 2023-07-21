variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}
# variable "tag_name" {
#   type        = string
#   description = "Environment Tag Name"
#   default     = "demo"
# }
variable "tenant_id" {
  description = "Azure Tenant ID"
}
variable "client_id" {
  type = string
  description = "Azure Client ID"
}
variable "client_secret" {
  type = string
  description = "Azure Client Secret"
}

# variable "admins" {
#   type = string
#   description = "Azure Admin ID"
# }
# variable "location" {
#   description = "Azure East location"
# }
variable "prefix" {
  type = string
  description = "Naming Prefix"
}
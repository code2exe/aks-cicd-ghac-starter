variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

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
variable "location" {
  description = "Azure Location"
}
variable "prefix" {
  type = string
  description = "Naming Prefix"
}
variable "pa_token" {
  description = "Token for GitHub"
}

variable "repo" {
  description = "Your repository name"
}
variable "repo_fullname" {
  description = "Your repository fullname"
}
variable "container_name" {
  description = "Container Name"
}
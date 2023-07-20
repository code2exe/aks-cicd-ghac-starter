provider "azurerm" {

    features {
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
  }
  # Configuration options

  client_id = var.client_id
  client_secret = var.client_secret

  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  skip_provider_registration = true
}

provider "local" {
  # Configuration options
}
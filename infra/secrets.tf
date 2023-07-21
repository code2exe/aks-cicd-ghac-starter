data "github_actions_public_key" "public_key" {
  repository = var.repo
}

data "github_repository" "repo" {
  full_name = var.repo_fullname
}

resource "github_actions_secret" "client_id" {
  repository       = data.github_repository.repo.name
  secret_name      = "AZURE_CLIENT_ID"
  plaintext_value  = var.client_id
}

resource "github_actions_secret" "tenant_id" {
  repository       = data.github_repository.repo.name
  secret_name      = "AZURE_TENANT_ID"
  plaintext_value  = var.tenant_id
}

resource "github_actions_secret" "client_secret" {
  repository       = data.github_repository.repo.name
  secret_name      = "AZURE_CLIENT_SECRET"
  plaintext_value  = var.client_secret
}

resource "github_actions_secret" "subscription_id" {
  repository       = data.github_repository.repo.name
  secret_name      = "AZURE_SUBSCRIPTION_ID"
  plaintext_value  = var.subscription_id
}

resource "github_actions_secret" "container_reg" {
  repository       = data.github_repository.repo.name
  secret_name      = "AZURE_CONTAINER_REGISTRY"
  plaintext_value  = azurerm_container_registry.example.name
}

resource "github_actions_secret" "container_name" {
  repository       = data.github_repository.repo.name
  secret_name      = "CONTAINER_NAME"
  plaintext_value  = var.container_name
}

resource "github_actions_secret" "resource_group" {
  repository       = data.github_repository.repo.name
  secret_name      = "RESOURCE_GROUP"
  plaintext_value  = azurerm_resource_group.aks.name
}

resource "github_actions_secret" "cluster_name" {
  repository       = data.github_repository.repo.name
  secret_name      = "CLUSTER_NAME"
  plaintext_value  = azurerm_kubernetes_cluster.aks.name
}
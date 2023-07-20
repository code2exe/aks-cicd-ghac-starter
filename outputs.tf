output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "vault_uri" {
  value = azurerm_key_vault.aks.vault_uri
}

output "cluster_egress_ip" {
  value = data.azurerm_public_ip.example.ip_address
}
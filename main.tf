data "azurerm_client_config" "current" {}

# data "azurerm_key_vault" "kv" {
#   name                = "atbkv"
#   resource_group_name = "KeyVault-RG"
# }

resource "azurerm_resource_group" "aks" {
  name     = "${var.prefix}-RG"
  location = "UK South"
}

resource "azurerm_key_vault" "aks" {
  name                        = "${var.prefix}-kv"
  location                    = azurerm_resource_group.aks.location
  resource_group_name         = azurerm_resource_group.aks.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = false

  sku_name = "standard"

  # access_policy {
  #   tenant_id = data.azurerm_client_config.current.tenant_id
  #   object_id = data.azurerm_client_config.current.object_id

  #   key_permissions = [
  #     "Get",
  #   ]

  #   secret_permissions = [
  #     "Get",
  #   ]

  #   storage_permissions = [
  #     "Get",
  #   ]
  # }
}



data "local_file" "config" {
  filename = "C:/Users/HenryEzedinma/.kube/config"
}

resource "azurerm_virtual_network" "aks" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = ["10.24.0.0/24"]
}

resource "azurerm_subnet" "aks" {
  name                 = "${var.prefix}-snet"
  resource_group_name  = azurerm_resource_group.aks.name
  address_prefixes     = ["10.24.0.0/28"]
  virtual_network_name = azurerm_virtual_network.aks.name
#   service_endpoints    = ["Microsoft.Sql"]
}



resource "azurerm_log_analytics_workspace" "example" {
  name                = "${var.prefix}-logs"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "PerGB2018"
  retention_in_days = 60
}

resource "azurerm_log_analytics_solution" "example" {
  solution_name         = "Containers"
  workspace_resource_id = azurerm_log_analytics_workspace.example.id
  workspace_name        = azurerm_log_analytics_workspace.example.name
  location              = azurerm_resource_group.aks.location
  resource_group_name   = azurerm_resource_group.aks.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
  }
}


data "azuread_service_principal" "example" {
  display_name = "k8s-demo"
}

resource "azurerm_role_assignment" "sp" {
  principal_id                     = data.azuread_service_principal.example.object_id
  role_definition_name             = "Key Vault Administrator"
  scope                            = azurerm_key_vault.aks.id
  skip_service_principal_aad_check = true
}

resource "azurerm_key_vault_key" "des" {
  name         = "${var.prefix}-des-key"
  key_vault_id = azurerm_key_vault.aks.id
  key_type     = "RSA"
  key_size     = 2048
  depends_on = [
    azurerm_role_assignment.sp
  ]
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_disk_encryption_set" "example" {
  name                = "${var.prefix}-des"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  key_vault_key_id    = azurerm_key_vault_key.des.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "example-disk" {
  scope                = azurerm_key_vault.aks.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_disk_encryption_set.example.identity.0.principal_id
}

resource "azurerm_key_vault_access_policy" "example-disk" {
  key_vault_id = azurerm_key_vault.aks.id

  tenant_id = azurerm_disk_encryption_set.example.identity.0.tenant_id
  object_id = azurerm_disk_encryption_set.example.identity.0.principal_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign",
  ]
}


resource "azurerm_key_vault_access_policy" "example-user" {
  key_vault_id = azurerm_key_vault.aks.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign",
    "GetRotationPolicy",
  ]
}



resource "azurerm_role_assignment" "kv" {
  principal_id                     = azurerm_user_assigned_identity.acr.principal_id
  role_definition_name             = "Key Vault Crypto Service Encryption User"
  scope                            = azurerm_key_vault.aks.id
  skip_service_principal_aad_check = true
}

# resource "azurerm_key_vault_key" "acr" {
#   name         = "${var.prefix}-acr-key"
#   key_vault_id = azurerm_key_vault.aks.id
#   key_type     = "RSA"
#   key_size     = 2048

#   depends_on = [
#     azurerm_role_assignment.kv
#   ]
#   key_opts = [
#     "decrypt",
#     "encrypt",
#     "sign",
#     "unwrapKey",
#     "verify",
#     "wrapKey",
#   ]
# }


resource "azurerm_role_assignment" "acr" {
  principal_id                     = azurerm_user_assigned_identity.acr.principal_id
  role_definition_name             = "Key Vault Crypto Service Encryption User"
  scope                            = azurerm_key_vault.aks.id
  skip_service_principal_aad_check = true
}

resource "azurerm_key_vault_key" "acr" {
  name         = "${var.prefix}-acr-key"
  key_vault_id = azurerm_key_vault.aks.id
  key_type     = "RSA"
  key_size     = 2048

  depends_on = [
    azurerm_role_assignment.kv
  ]
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}


resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "DiagnosticsSettings"
  target_resource_id         = azurerm_key_vault.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "AuditEvent"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }
}



resource "azurerm_user_assigned_identity" "acr" {
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  name = "${var.prefix}-acr-uid"
}

resource "azurerm_container_registry" "example" {
  name                = "oagacreg"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "Premium"

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.acr.id
    ]
  }

  encryption {
    enabled            = true
    key_vault_key_id   = azurerm_key_vault_key.acr.id
    identity_client_id = azurerm_user_assigned_identity.acr.client_id
  }
}

resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                       = "DiagnosticsSettings"
  target_resource_id         = azurerm_container_registry.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }
}

data "azurerm_kubernetes_service_versions" "current" {
  location = azurerm_resource_group.aks.location
}


resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "${var.prefix}"
  node_resource_group = "${var.prefix}-Node-RG"
  image_cleaner_enabled = true
  image_cleaner_interval_hours = 72
  local_account_disabled = true
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current.latest_version
  disk_encryption_set_id = azurerm_disk_encryption_set.example.id

  azure_active_directory_role_based_access_control {
    managed = false
    # admin_group_object_ids = var.admins
    client_app_id = var.client_id
    server_app_id = var.client_id
    server_app_secret = var.client_secret
    
  }


  default_node_pool {
    zones   = [1, 2, 3]
    enable_auto_scaling = true
    enable_host_encryption = true
    max_count = 3
    min_count = 1
    name       = "system"
    orchestrator_version = data.azurerm_kubernetes_service_versions.current.latest_version
    vm_size    = "Standard_B2s"
    os_sku = "Mariner"
    os_disk_size_gb = 50
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.example.id
    msi_auth_for_monitoring_enabled = true
  }

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  mode = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_B2s"
  node_count            = 1
  os_sku = "Mariner"
  os_disk_size_gb = 128
  orchestrator_version = data.azurerm_kubernetes_service_versions.current.latest_version
  vnet_subnet_id        = azurerm_subnet.aks.id
  zones   = [1, 2, 3]
  enable_auto_scaling = true
  max_count = 4
  min_count = 1
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "DiagnosticsSettings"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "kube-apiserver"

    retention_policy {
      enabled = true  
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }

  enabled_log {
    category = "kube-audit"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }

  enabled_log {
    category = "kube-audit-admin"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }

  enabled_log {
    category = "kube-controller-manager"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }

  enabled_log {
    category = "kube-scheduler"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }

  enabled_log {
    category = "cluster-autoscaler"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }

  enabled_log {
    category = "guard"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.example.retention_in_days
    }
  }
}



resource "azurerm_role_assignment" "example" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.example.id
  skip_service_principal_aad_check = true
}


data "azurerm_public_ip" "example" {
  name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.aks.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
}

resource "local_file" "config" {
  source = azurerm_kubernetes_cluster.aks.kube_config_raw
  filename = data.local_file.config.filename
}
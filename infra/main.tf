data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "aks" {
  name     = "${var.prefix}-rg"
  location = var.location
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

resource "azurerm_container_registry" "example" {
  name                = "cr${var.prefix}"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "Standard"
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
  node_resource_group = "${var.prefix}-node-rg"
  local_account_disabled = false
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current.latest_version
  http_application_routing_enabled = true

  azure_active_directory_role_based_access_control {
    managed = true
    # client_app_id = var.client_id
    # server_app_id = var.client_id
    # server_app_secret = var.client_secret
    
  }


  default_node_pool {
    zones   = [1, 2, 3]
    enable_auto_scaling = true
    max_count = 3
    min_count = 1
    name       = "system"
    orchestrator_version = data.azurerm_kubernetes_service_versions.current.latest_version
    vm_size    = "Standard_DS2_v2"
    os_sku = "Mariner"
    os_disk_size_gb = 32
    vnet_subnet_id = azurerm_subnet.aks.id
    temporary_name_for_rotation = var.prefix
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
  vm_size               = "Standard_DS2_v2"
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

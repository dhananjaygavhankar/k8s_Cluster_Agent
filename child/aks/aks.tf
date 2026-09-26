resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.rg_location
  resource_group_name = var.name_rg
  dns_prefix          = var.dns_prefix

  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = var.vm2take
    vnet_subnet_id = var.subnet_id

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.1.0.0/16"
    dns_service_ip      = "10.1.0.10"
    load_balancer_sku   = "standard"
  }

  private_cluster_enabled = false

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.name_rg
  location            = var.rg_location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "terraform_acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_client_config.current.object_id
}

output "acr_login_server" {
  description = "Login server for pushing and pulling container images"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_id" {
  description = "Resource ID of the created Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

resource "azurerm_virtual_network" "aks_vnet" {
  name                = var.aks_vnet
  location            = var.rg_location
  resource_group_name = var.name_rg
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.name_rg
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

output "subnet_id" {
  description = "ID of the subnet assigned to the AKS node pool"
  value       = azurerm_subnet.aks_subnet.id
}

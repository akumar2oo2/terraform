# Create a resource group
resource "azurerm_resource_group" "Resource" {
  name     = local.resource_group_name
  location = local.location
}

# Create a storage account
resource "azurerm_storage_account" "Storage" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.Resource.name
  location                 = azurerm_resource_group.Resource.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a container
resource "azurerm_storage_container" "Container" {
  name                  = local.container_name
  storage_account_name  = azurerm_storage_account.Storage.name
  container_access_type = "private"
}

# Create a blob for each .tf file
resource "azurerm_storage_blob" "blob" {
  for_each               = toset(local.blob_files)
  name                   = each.value
  storage_account_name   = azurerm_storage_account.Storage.name
  storage_container_name = azurerm_storage_container.Container.name
  type                   = "Block"
  source                 = "${path.module}/${each.value}"
}

# Create a vnet
resource "azurerm_virtual_network" "vnet" {
  name                = local.virtual_network.vnet_name
  location            = azurerm_resource_group.Resource.location
  resource_group_name = azurerm_resource_group.Resource.name
  address_space       = local.virtual_network.address_space

  dynamic "subnet" {
    for_each = local.virtual_network.subnets

    content {
      name             = "${local.virtual_network.vnet_name}-${subnet.key}"
      address_prefixes = subnet.value.address_prefixes
    }
  }
}
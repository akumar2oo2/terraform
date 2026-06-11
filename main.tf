# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}

# Create a storage account
resource "azurerm_storage_account" "storage" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a container
resource "azurerm_storage_container" "container" {
  name                  = local.container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# Create a blob for each .tf file
resource "azurerm_storage_blob" "blob" {
  for_each = toset(local.blob_files)

  name                   = each.value
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "${path.module}/${each.value}"
}

# Create a vnet
resource "azurerm_virtual_network" "vnet" {
  name                = local.virtual_network.vnet_name
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = local.virtual_network.address_space
}

resource "azurerm_subnet" "subnet" {
  for_each = local.virtual_network.subnets

  name                 = "${local.virtual_network.vnet_name}-${each.key}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

#Create a NIC
resource "azurerm_network_interface" "nic" {
  for_each = local.virtual_network.subnets

  name                = "${each.key}-nic"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig-${each.key}"
    subnet_id                     = azurerm_subnet.subnet[each.key].id
    private_ip_address_allocation = local.ip_configuration.private_ip_address_allocation
    public_ip_address_id          = azurerm_public_ip.public[each.key].id
  }
}

resource "azurerm_public_ip" "public" {
  for_each = local.virtual_network.subnets

  name                = "PublicIp-${each.key}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "nsg" {
  for_each = local.virtual_network.subnets

  name                = "nsg-${each.key}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "sr-nsg-${each.key}"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = local.virtual_network.subnets

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each = local.virtual_network.subnets

  name                = "VM-${regex("[0-9]+", each.key)}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
  size                = "Standard_D2alds_v6"
  admin_username      = "adminuser"
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "datadisk" {
  for_each = local.virtual_network.subnets

  name                 = "Disk-${regex("[0-9]+", each.key)}"
  location             = local.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
  for_each = local.virtual_network.subnets

  managed_disk_id    = azurerm_managed_disk.datadisk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm[each.key].id
  lun                = 0
  caching            = "ReadWrite"
}
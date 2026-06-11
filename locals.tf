locals {
  # Common resource configuration
  resource_group_name = "MyRG"
  location            = "centralindia"

  # Naming conventions for storage and container
  storage_account_name = "akstorage7347379"
  container_name       = "akcontainer" 

  # List of files to be uploaded as blobs
  blob_files = [
  "main.tf",
  "locals.tf",
  "provider.tf",
  "variables.tf"
  ]

  # Naming conventions for vnet and subnet
  virtual_network = {
    vnet_name            = "ak-vnet"
    address_space        = ["10.0.0.0/16"]
    subnets = {
      subnet1 = {
        address_prefixes = ["10.0.1.0/24"]
      }
      subnet2 = {
        address_prefixes = ["10.0.2.0/24"]
      }
      subnet3 = {
        address_prefixes = ["10.0.3.0/24"]
      }
    }
  }
}
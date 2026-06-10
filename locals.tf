locals {
  # Common resource configuration
  resource_group_name = "MyRG"
  location            = "West Europe"

  # Naming conventions for resources
  storage_account_name = "akstorage7347379"
  container_name       = "akcontainer"
  vnet_name            = "ak-vnet"

  # List of files to be uploaded as blobs
  blob_files = [
  "main.tf",
  "locals.tf",
  "provider.tf",
  "variables.tf"
  ]

}
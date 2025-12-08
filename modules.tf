resource "azurerm_resource_group" "example" {
  name     = "example"
  location = "West Europe"
}
resource "azurerm_resource_vm" "example" {
  name     = "example-vm"
  location = "West Europe"
}
resource "azurerm_resource_vnet" "example" {
  name     = "example-vnet"
  location = "West Europe"
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.6.0"
    }
  }
}

provider "azurerm" {
    # Configuration options
}

data "azurerm_resource_group" "rg" {
  name = "<existing RG name>"
}

resource "azurerm_container_registry" "acr" {
    name = "cr703407734"
    resource_group_name = data.azurerm_resource_group.rg.name
    location = data.azurerm_resource_group.rg.location
    sku = "Basic"
}
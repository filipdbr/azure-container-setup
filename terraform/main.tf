# the latest version for today 04/05/2026
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.71.0"
    }
  }
}

provider "azurerm" {
  features {

  }
}

# define the resource group
resource "azurerm_resource_group" "immich-deployment" {
  name     = "immich-prod"
  location = "polandcentral"
}

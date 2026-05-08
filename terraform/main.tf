# Global configuration: Terraform providers and main Resource Group

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
    key_vault {

      # as it is a lab, destroy key vault upon 'terraform destroy' command without keeping it in soft delete state for 90 days
      purge_soft_delete_on_destroy = true

      # if key vault was deleted it can be recovered upon 'terraform apply'
      recover_soft_deleted_key_vaults = true
    }

  }
}

# define the resource group
resource "azurerm_resource_group" "immich_rg" {
  name     = var.rg_name
  location = var.location
}
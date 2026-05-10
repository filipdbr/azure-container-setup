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

# create an inventory file for ansible based on the deployment
resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory.ini"

  content = <<-EOF
    [immich_servers]
    ${azurerm_public_ip.immich_public_ip.ip_address}

    [immich_servers:vars]
    ansible_user=${var.admin_username}
    ansible_connection=ssh
    ansible_ssh_private_key_file=~/.ssh/id_rsa
    ansible_python_interpreter=/usr/bin/python3
    ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOF
}
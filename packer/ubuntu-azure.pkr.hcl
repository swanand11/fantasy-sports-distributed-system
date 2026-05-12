packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2.0"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1.0"
    }
  }
}

variable "client_id" {
  type = string
  default = env("ARM_CLIENT_ID")
}

variable "client_secret" {
  type = string
  default = env("ARM_CLIENT_SECRET")
}

variable "subscription_id" {
  type = string
  default = env("ARM_SUBSCRIPTION_ID")
}

variable "tenant_id" {
  type = string
  default = env("ARM_TENANT_ID")
}

source "azure-arm" "ubuntu" {
  client_id                         = "${var.client_id}"
  client_secret                     = "${var.client_secret}"
  subscription_id                   = "${var.subscription_id}"
  tenant_id                         = "${var.tenant_id}"
  
  managed_image_resource_group_name = "devops-rg"
  managed_image_name                = "ubuntu-devops-agent-{{timestamp}}"
  
  os_type                           = "Linux"
  image_publisher                   = "Canonical"
  image_offer                       = "0001-com-ubuntu-server-focal"
  image_sku                         = "20_04-lts"
  
  azure_tags = {
    dept = "engineering"
    task = "devops-project"
  }
  
  location                          = "East US"
  vm_size                           = "Standard_B2s"
}

build {
  sources = ["source.azure-arm.ubuntu"]

  provisioner "ansible" {
    playbook_file = "../ansible/playbook.yml"
  }
}

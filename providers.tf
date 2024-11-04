terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.49"
    }
    vsphere = {
      source = "hashicorp/vsphere"
      version = "~> 2.5"
    }
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.4"
    }

    hcp = {
      source = "hashicorp/hcp"
      version = "~> 0.97.0"
    }
  }


  cloud {
    organization = "tfo-apj-demos"
    workspaces {
      name = "vsphere-hcp-tfc-agents"
    }
  }
}

provider "tfe" {
  organization = var.organization
}

provider "vsphere" {}
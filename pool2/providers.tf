terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.49"
    }
    vsphere = {
      source  = "vmware/vsphere"
      version = "~> 2.5"
    }
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.4"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.97"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }

  cloud {
    organization = "tfo-apj-demos"
    workspaces {
      name    = "terraform-vsphere-hcp-tfc-agents-pool2"
      project = "10 - gcve-foundations"
    }
  }
}

provider "tfe" {
  organization = var.organization
}

# Vault authenticates automatically via TFC workload identity dynamic
# credentials (the TFC_VAULT_* env vars from the __gcve_workspace_identity_tfc
# varset). No static Vault token required.
provider "vault" {}

# Read the current vm_builder vCenter password from Vault at run time, so the
# vSphere provider always uses a fresh credential instead of a static copy in
# the __gcve_vcenter_variables varset (which goes stale on Vault's 7-day rotation).
data "vault_ldap_static_credentials" "vm_builder" {
  mount     = "ldap"
  role_name = "vm_builder"
}

provider "vsphere" {
  user     = "${data.vault_ldap_static_credentials.vm_builder.username}@hashicorp.local"
  password = data.vault_ldap_static_credentials.vm_builder.password
  # vsphere_server + allow_unverified_ssl continue to come from the VSPHERE_*
  # env vars (VSPHERE_SERVER in __gcve_vcenter_variables).
}

provider "nsxt" {
  max_retries = 3
}

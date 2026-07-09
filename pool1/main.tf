data "hcp_packer_artifact" "this" {
  bucket_name  = "docker-ubuntu-2204"
  channel_name = "latest"
  platform     = "vsphere"
  region       = "Datacenter"
}

data "tfe_agent_pool" "this" {
  name         = var.agent_pool_name
  organization = var.organization
}

resource "tfe_agent_token" "this" {
  agent_pool_id = data.tfe_agent_pool.this.id
  description   = "agent token for vsphere environment - pool1"
}

data "nsxt_policy_ip_pool" "this" {
  display_name = "10 - gcve-foundations"
}

resource "nsxt_policy_ip_address_allocation" "this" {
  count        = var.agent_count
  display_name = "${var.hostname_prefix}-${count.index}"
  pool_path    = data.nsxt_policy_ip_pool.this.path
}

module "vm" {
  count = var.agent_count

  source  = "app.terraform.io/tfo-apj-demos/virtual-machine/vsphere"
  version = "~> 2.0"

  hostname          = "${var.hostname_prefix}-${count.index}"
  datacenter        = "Datacenter"
  cluster           = "cluster"
  resource_pool     = "Demo Management"
  primary_datastore = "vsanDatastore"
  folder_path       = "Demo Management"
  networks = {
    "seg-general" : "${nsxt_policy_ip_address_allocation.this[count.index].allocation_ip}/22"
  }
  dns_server_list = [
    "172.21.15.150"
  ]
  gateway         = "172.21.12.1"
  dns_suffix_list = ["hashicorp.local"]

  template = data.hcp_packer_artifact.this.external_identifier

  userdata = templatefile("${path.module}/templates/userdata.yaml.tmpl", {
    agent_token               = tfe_agent_token.this.token
    agent_name                = "${var.hostname_prefix}-${count.index}"
    krb5_conf                 = base64encode(templatefile("${path.module}/templates/krb5.conf.tmpl", {}))
    enable_request_forwarding = var.enable_request_forwarding
    agent_image               = var.agent_image
  })
  tags = {
    "application" = "tfc-agent"
  }
}

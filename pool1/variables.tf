variable "organization" {
  description = "The Terraform Cloud organization name."
  type        = string
  default     = "tfo-apj-demos"
}

variable "agent_count" {
  description = "Number of Terraform agents to deploy."
  type        = number
  default     = 4
}

variable "enable_request_forwarding" {
  description = "Enable request forwarding for Terraform agents."
  type        = bool
  default     = true
}

variable "agent_pool_name" {
  description = "Name of the existing HCP Terraform agent pool that the pool1 VMs (hcp-tfc-agent-1-0/1/2/3) register against. Referenced read-only via data source — this workspace does not own the pool resource. The pool is shared with all other workspaces in the TFC org."
  type        = string
  default     = "gcve_agent_pool1"
}

variable "hostname_prefix" {
  description = "Prefix for VM hostnames and agent names. `-<count.index>` is appended (e.g. `hcp-tfc-agent-1-0`)."
  type        = string
  default     = "hcp-tfc-agent-1"
}

variable "agent_image" {
  description = "Container image for the HCP Terraform agent (must trust the internal CA chain)."
  type        = string
  default     = "ghcr.io/tfo-apj-demos/tfc-agent:latest"
}

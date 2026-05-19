variable "organization" {
  description = "The Terraform Cloud organization name."
  type        = string
  default     = "tfo-apj-demos"
}

variable "agent_count" {
  description = "Number of Terraform agents to deploy."
  type        = number
  default     = 1
}

variable "enable_request_forwarding" {
  description = "Enable request forwarding for Terraform agents."
  type        = bool
  default     = true
}

variable "agent_pool_name" {
  description = "Name of the existing HCP Terraform agent pool that the agent0/1/2 VMs register against. Referenced read-only via data source - this workspace does not own the pool resource."
  type        = string
  default     = "gcve_agent_pool3"
}

variable "hostname_prefix" {
  description = "Prefix for VM hostnames. count.index is appended."
  type        = string
  default     = "hcp-tfc-agent"
}

variable "agent_image" {
  description = "Container image for the HCP Terraform agent (must trust the internal CA chain)."
  type        = string
  default     = "ghcr.io/tfo-apj-demos/tfc-agent:latest"
}

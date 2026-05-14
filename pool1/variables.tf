variable "organization" {
  description = "The Terraform Cloud organization name."
  type        = string
  default     = "tfo-apj-demos"
}

variable "agent_count" {
  description = "Number of Terraform agents to deploy."
  type        = number
  default     = 3
}

variable "enable_request_forwarding" {
  description = "Enable request forwarding for Terraform agents."
  type        = bool
  default     = true
}

variable "agent_pool_name" {
  description = "Name of the HCP Terraform agent pool to manage."
  type        = string
  default     = "gcve_agent_pool1"
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

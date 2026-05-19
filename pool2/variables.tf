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
  description = "Name of the HCP Terraform agent pool managed by this workspace. The agents in this pool (hcp-tfc-agent-2-0/1/2) execute the pool1 workspace's runs — cross-managed so that recreating pool1 VMs doesn't kill its own apply. See README \"Cross-managed execution\"."
  type        = string
  default     = "gcve_agent_pool2"
}

variable "hostname_prefix" {
  description = "Prefix for VM hostnames and agent names. `-<count.index>` is appended (e.g. `hcp-tfc-agent-2-0`)."
  type        = string
  default     = "hcp-tfc-agent-2"
}

variable "agent_image" {
  description = "Container image for the HCP Terraform agent (must trust the internal CA chain)."
  type        = string
  default     = "ghcr.io/tfo-apj-demos/tfc-agent:latest"
}

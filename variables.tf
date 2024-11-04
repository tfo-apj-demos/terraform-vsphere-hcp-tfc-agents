variable "organization" {
  description = "The Terraform Cloud organization name."
  type        = string
}

variable "agent_count" {
  description = "Number of Terraform agents to deploy."
  type = number
  default = 3
}

variable "enable_request_forwarding" {
  description = "Enable request forwarding for Terraform agents."
  type = bool
  default = true
}
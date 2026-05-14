output "agent_pool_id" {
  value = tfe_agent_pool.this.id
}

output "agent_pool_name" {
  value = tfe_agent_pool.this.name
}

output "agent_vm_ips" {
  value = [for v in module.vm : v.ip_address]
}

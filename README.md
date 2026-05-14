# terraform-vsphere-hcp-tfc-agents

Provisions and maintains the Ubuntu VMs that host HCP Terraform Agent containers in a vSphere environment. The agents in turn execute runs for workspaces that need to reach private endpoints (vCenter, NSX-T, internal HTTPS APIs) that HCP Terraform's managed runners can't see.

This repo manages **agent fleet capacity** — the VMs, the per-pool agent token, the NSX-T IP allocations, and the container image those VMs run. The agent pools themselves are referenced read-only in one subdir and managed-as-resource in another; see "Pool ownership" below.

## Repo layout

```
agent-image/
  Dockerfile             FROM hashicorp/tfc-agent + internal CA chain
  ca-chain.pem           Vault PKI intermediate + central signing CA
pool1/
  main.tf                3 VMs, 1 fresh token under an existing pool (data source)
  providers.tf           cloud{} block pinned to its HCP Terraform workspace
  variables.tf           hostname_prefix, agent_pool_name, agent_image, etc.
  templates/
    userdata.yaml.tmpl   cloud-init: docker pull <agent_image>; docker run
    krb5.conf.tmpl       Kerberos config baked into the container
    metadata.yaml.tmpl   network + hostname injected via vmware datasource
pool2/
  ... same shape, different pool name, different hostname prefix
```

Each `poolN/` subdir is an independent Terraform root module that maps 1:1 to its own HCP Terraform workspace. The workspaces are VCS-driven with `working-directory` and `trigger-prefixes` set so that a commit touching only `pool1/` fires only the pool1 workspace, not pool2.

## Pool ownership pattern

There are two flavors of pool reference in this repo, intentionally different:

- **pool1/** uses `data "tfe_agent_pool" "this"` — read-only. The pool already exists (created out-of-band or by another tool) and is shared with many other workspaces in the org. This workspace creates a **fresh token** under it for its own VMs to register against but does **not** own the pool's lifecycle. Useful when you want Terraform to manage agent capacity (VMs) without risking accidental destruction of a pool that other workspaces depend on.
- **pool2/** uses `resource "tfe_agent_pool" "this"` — fully managed. The workspace owns the pool's lifecycle. Appropriate when the pool exists solely to host this workspace's agents.

Pick whichever fits when adding a new pool. The data-source flavor is safer for shared pools.

## Why the custom agent image

The default `hashicorp/tfc-agent:latest` image trusts only public CAs. In private environments where internal services (Vault-issued certs on `*.internal.example`) are reached during a plan/apply, the agent's HTTP client fails TLS handshake.

The `agent-image/` Dockerfile installs the internal CA chain via `update-ca-certificates` so the agent trusts internal endpoints without per-provider `insecure_skip_verify` flags. The chain file is the issuing intermediate + the trust-anchor CA; commit only public-key PEMs, never private keys.

### Building & publishing

The agent VMs pull the image at boot. It needs to be published to a registry the VMs can reach.

```sh
# multi-arch (recommended; covers arm64 build hosts and amd64 VMs)
docker buildx build \
  --platform=linux/amd64,linux/arm64 \
  -t ghcr.io/<org>/tfc-agent:latest \
  --push \
  agent-image/
```

Pinning to a digest rather than `:latest` in `variables.tf` `agent_image` is recommended for reproducibility. The default uses `:latest` for demo simplicity.

## Cross-managed execution (avoid self-management)

The trap: a workspace that manages a pool, and *executes* on agents in that same pool, can deadlock on apply. If the apply destroys/recreates VMs that host the active agent, the run dies mid-apply with no agent to report back.

The convention in this repo:

- **pool1's workspace** executes on **pool2's** agents.
- **pool2's workspace** executes on **pool1's** agents (or any other independent pool).

This is set on the workspace via `agent-pool` relationship in HCP Terraform, not in HCL. Confirm in the HCP Terraform UI under Settings → General → Execution Mode → Agent pool.

## Rolling agent VMs

The VM module ignores changes to `extra_config` (which holds the rendered userdata), so a userdata change — e.g. updating the agent image — won't show as a plan diff. To actually pick up the new image, force replacement on apply:

```sh
terraform apply \
  -replace=module.vm[0].vsphere_virtual_machine.this \
  -replace=module.vm[1].vsphere_virtual_machine.this \
  -replace=module.vm[2].vsphere_virtual_machine.this
```

Or in HCP Terraform, trigger a new run with `replace-addrs` set (API) or "Replace resources" checked (UI). To avoid pool downtime, do them one at a time and wait for each new agent to register before the next.

## Architecture diagram

```
HCP Terraform workspace (poolN)
  │
  ├─ data.tfe_agent_pool or resource.tfe_agent_pool   (pool reference)
  ├─ resource.tfe_agent_token                         (fresh token)
  ├─ nsxt_policy_ip_address_allocation                (one per VM)
  └─ module.vm × var.agent_count
        │
        └─ vsphere_virtual_machine
              userdata = templatefile(.../userdata.yaml.tmpl, {
                agent_token = tfe_agent_token.this.token
                agent_image = var.agent_image
                ...
              })
              │
              cloud-init on boot
                  docker pull <agent_image>
                  docker run --restart always <agent_image>
                    └─ tfc-agent registers to pool via TFC_AGENT_TOKEN
```

## Adding a new pool

1. Copy `pool1/` (data-source flavor) or `pool2/` (resource flavor) to `poolN/`.
2. Update `providers.tf` cloud block: workspace name.
3. Update `variables.tf` defaults: `agent_pool_name`, `hostname_prefix`.
4. In HCP Terraform, create the workspace, attach the same VCS repo, set `working-directory = poolN`, `trigger-prefixes = ["poolN/", "agent-image/"]`.
5. Set the workspace's execution agent pool to an *independent* pool (not the one this workspace will manage).
6. Plan from the UI to confirm shape, then apply.

## File-by-file purpose

| File | Purpose |
|------|---------|
| `agent-image/Dockerfile` | Custom tfc-agent image with internal CA bundle baked in |
| `agent-image/ca-chain.pem` | Vault PKI issuing intermediate + central signing CA (public PEMs only) |
| `poolN/main.tf` | Pool reference, token, NSX-T IP allocations, VM module instantiation |
| `poolN/providers.tf` | Required providers, HCP Terraform cloud block pinned to workspace |
| `poolN/variables.tf` | `agent_count`, `agent_pool_name`, `hostname_prefix`, `agent_image`, etc. |
| `poolN/outputs.tf` | `agent_pool_id`, `agent_pool_name`, `agent_vm_ips` for downstream consumers |
| `poolN/templates/userdata.yaml.tmpl` | cloud-init that pulls image and starts the agent |
| `poolN/templates/krb5.conf.tmpl` | Kerberos client config (mounted into the container for AD-aware workloads) |
| `poolN/templates/metadata.yaml.tmpl` | cloud-init datasource metadata (hostname, network) |

#MIT License

#Copyright (c) 2026 Qumulo, Inc.

#Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the Software), to deal 
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all 
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
#SOFTWARE.

output "cluster_name" {
  description = "Name of the Qumulo cluster"
  value       = qumulo_filesystem_aws.cluster.name
}

output "cluster_uuid" {
  description = "UUID of the Qumulo cluster"
  value       = qumulo_filesystem_aws.cluster.cluster_uuid
}

output "deployment_unique_name" {
  description = "Unique deployment identifier"
  value       = qumulo_filesystem_aws.cluster.deployment_unique_name
}

output "endpoint_ips" {
  description = "Client-facing IPs. Floating IPs if configured, otherwise primary IPs."
  value       = !local.provision_nlb ? qumulo_filesystem_aws.cluster.endpoint_ips : null
}

output "primary_ips" {
  description = "Per-node primary IPs. Use these directly when no floating IPs are configured, or for per-node access."
  value       = qumulo_filesystem_aws.cluster.primary_ips
}

output "soft_capacity_limit_tb" {
  description = "Total capacity the cluster may consume.  Only used capacity is billed."
  value       = qumulo_filesystem_aws.cluster.soft_capacity_limit_tb
}

output "endpoints" {
  description = "Connection endpoints for various protocols"
  value = {
    web_ui = local.provision_nlb ? module.nlb[0].url : (local.provision_resolver ? module.route53-resolver[0].url : "https://${try(qumulo_filesystem_aws.cluster.endpoint_ips[0], "pending")}")
    api    = local.provision_nlb ? module.nlb[0].api : (local.provision_resolver ? module.route53-resolver[0].api : "https://${try(qumulo_filesystem_aws.cluster.endpoint_ips[0], "pending")}:8000")
    nfs    = local.provision_nlb ? module.nlb[0].nfs : (local.provision_resolver ? module.route53-resolver[0].nfs : "${try(qumulo_filesystem_aws.cluster.endpoint_ips[0], "pending")}:/<NFS Export Name>")
    smb    = local.provision_nlb ? module.nlb[0].smb : (local.provision_resolver ? module.route53-resolver[0].smb : "\\${try(qumulo_filesystem_aws.cluster.endpoint_ips[0], "pending")}\\<SMB Share Name>")
  }
}

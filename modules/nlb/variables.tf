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

variable "cluster_primary_ips" {
  description = "List of all primary IPs for the Qumulo cluster"
  type        = list(string)
}
variable "cross_zone" {
  description = "AWS NLB Enable cross-AZ load balancing"
  type        = bool
}
variable "deletion_protection" {
  description = "Enable Deletion Protection"
  type        = bool
}
variable "deployment_unique_name" {
  description = "Unique Name for this Terraform deployment.  This is the deployment name plus 6 random alphanumeric digits that will be used for all resource names where appropriate."
  type        = string
}
variable "dereg_delay" {
  description = "AWS NLB deregistration delay"
  type        = number
}
variable "dereg_term" {
  description = "AWS NLB terminate connection on deregistration"
  type        = bool
}
variable "dns_record_client_routing_policy" {
  description = "AWS NLB DNS Client Zonal Affinity"
  type        = string
}
variable "ip_address_type" {
  description = "AWS NLB IP address type"
  type        = string
}
variable "is_public" {
  description = "OPTIONAL: Makes the NLB for the cluster public, setting this to true will allow anyone to reach the cluster.  Not recommended for production clusters."
  type        = bool
  default     = false
}
variable "node_count" {
  description = "Qumulo cluster node count"
  type        = number
}
variable "override_subnet_ids" {
  description = "AWS subnet identifiers"
  type        = list(string)
}
variable "preserve_ip" {
  description = "AWS NLB preserve IP address"
  type        = bool
}
variable "proxy_proto_v2" {
  description = "AWS NLB proxy header"
  type        = bool
}
variable "stickiness" {
  description = "AWS NLB sticky sessions"
  type        = bool
}
variable "subnet_ids" {
  description = "AWS subnet identifiers"
  type        = list(string)
}
variable "tags" {
  description = "Additional global tags"
  type        = map(string)
}
variable "vpc_id" {
  description = "AWS VPC identifier"
  type        = string
}

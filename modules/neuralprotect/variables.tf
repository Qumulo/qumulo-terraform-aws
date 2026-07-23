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

variable "additional_security_group_ids" {
  description = "OPTIONAL: Use for adding custom ingress rules beyond those the provider creates"
  type        = list(string)
}

variable "allow_cidrs" {
  description = "OPTIONAL: CIDR blocks allowed to access the NeuralProtect instance"
  type        = list(string)
}

variable "cluster_admin_password" {
  description = "The cluster admin password"
  type        = string
  sensitive   = true
}

variable "cluster_dns_name" {
  description = "OPTIONAL: The DNS name used for the cluster"
  type        = string
}

variable "cluster_reference" {
  description = "Aggregated cluster identity"
  type = object({
    cluster_name         = string
    cluster_uuid         = string
    endpoint_ips         = list(string)
    region               = string
    subnet_ids           = list(string)
    uses_floating_ips    = bool
    vpc_cidr             = string
    vpc_id               = string
    cluster_api_endpoint = string
  })
}

variable "deletion_protection" {
  description = "Enables EC2 Termination protection"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "NeuralProtect EC2 instance type."
  type        = string
}

variable "kms_key_id" {
  description = "OPTIONAL: KMS key ARN for encrypting AWS services like EBS and S3 (immutable after creation). Default AWS KMS key will be used if unspecified."
  type        = string
}

variable "permissions_boundary_arn" {
  description = "OPTIONAL: IAM permissions boundary ARN applied to the NeuralProtect role"
  type        = string
}

variable "tags" {
  description = "OPTIONAL: Tags to apply to all AWS resources created for this cluster."
  type        = map(string)
}
#MIT License

#Copyright (c) 2026 Qumulo, Inc.

#Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the Software), to deal 
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions =

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
  default     = null
  nullable    = true
}

variable "admin_pwd_or_secrets_arn" {
  type        = string
  sensitive   = true
  description = "Provide either a plaintext administrator password or an AWS Secrets Manager ARN."

  validation {
    condition = (
      # Option A: Valid AWS Secrets Manager ARN Format
      can(regex("^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:.+$", var.admin_pwd_or_secrets_arn)) ||

      # Option B: Plaintext Password Criteria (broken into simple, absolute checks)
      # Option B: Plaintext Password Criteria
      (
        length(var.admin_pwd_or_secrets_arn) >= 8 &&
        length(var.admin_pwd_or_secrets_arn) <= 128 &&
        can(regex("[A-Z]", var.admin_pwd_or_secrets_arn)) &&  # At least one uppercase letter
        can(regex("[a-z]", var.admin_pwd_or_secrets_arn)) &&  # At least one lowercase letter
        can(regex("[^a-zA-Z]", var.admin_pwd_or_secrets_arn)) # At least one character that is NOT a letter (number or symbol)
      )
    )
    error_message = "The admin_pwd_or_secrets_arn must be either a valid AWS Secrets Manager ARN, or a password that is 8-128 characters long containing at least one uppercase letter, one lowercase letter, and one number or special character."
  }
}

variable "allow_cidrs" {
  description = "OPTIONAL: CIDR blocks allowed to access the cluster"
  type        = list(string)
  default     = null
  nullable    = true
}

variable "ami_id" {
  description = "OPTIONAL: AMI ID for cluster nodes. If omitted, the default Qumulo AMI (Ubuntu 24.04) is used. Supports Ubuntu and RHEL 8, 9, and 10 AMIs. See aws-custom-images.md for details."
  type        = string
  default     = null
  nullable    = true
}

variable "cluster_dns_name" {
  description = "OPTIONAL: DNS Name for the cluster.  Leave null to automatically pickup the QDNS or NLB DNS name."
  type        = string
  default     = null
  nullable    = true
}

variable "cluster_fqdn" {
  description = "OPTIONAL: Fully qualified domain name for Qumulo DNS"
  type        = string
  default     = null
  validation {
    condition     = var.cluster_fqdn == null || can(regex("^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$", var.cluster_fqdn))
    error_message = "The fqdn must use lowercase, start and end with letters only, and may contain . and -"
  }
}

variable "cluster_iam_role_arn" {
  type        = string
  default     = null
  nullable    = true
  description = "OPTIONAL: When set, the provider performs no IAM writes for that role — no creation, policy updates, tagging, or deletion — and instead launches instances with your role's instance profile"

  validation {
    condition     = var.cluster_iam_role_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.cluster_iam_role_arn))
    error_message = "Must be either null or a valid AWS IAM ARN for the role the cluster will use."
  }
}

variable "cluster_name" {
  description = "Cluster name (2-15 alphanumeric characters). Used as a prefix for AWS resources created for this cluster."
  type        = string
  nullable    = false
}

variable "cluster_product_type" {
  description = "Cluster storage product type (immutable after creation). HOT: Optimized for frequently accessed data. COLD: Optimized for archival/infrequently accessed data."
  type        = string
  nullable    = false
}

variable "cluster_security_group_id" {
  description = "OPTIONAL: Bring-your-own security group ID for cluster nodes. When set, the provider will not create or modify a cluster security group; you must pre-create it in the VPC owner account with the rules documented in the Bring-your-own Security Groups guide. Required together with provisioner_security_group_id. Required for RAM-shared subnets where the consumer account cannot create security groups in the owner's VPC."
  type        = string
  default     = null
  nullable    = true
}

variable "cluster_version" {
  description = "OPTIONAL: Qumulo software version. Defaults to latest. Immutable after creation. Upgrade version via cluster UI/API."
  type        = string
  default     = null
  nullable    = true
}

variable "deletion_protection" {
  description = "Enables EC2 Termination protection and prevents Terraform from destroying non-empty S3 Buckets"
  type        = bool
  default     = true
}

variable "deployment_name" {
  description = "Cluster name (2-15 alphanumeric characters). Used as a prefix for AWS resources created for this cluster."
  type        = string
  nullable    = false
}

variable "ec2_key_pair" {
  description = "EC2 key pair name for SSH access to cluster nodes"
  type        = string
  nullable    = false
}

variable "floating_ip_count" {
  description = "OPTIONAL: Number of floating IPs. Must be 0, or between 3 and 100. NOT applicable with multi-AZ deployments."
  type        = number
  default     = 3
  nullable    = false
}

variable "instance_type" {
  description = "EC2 instance type for the cluster. Prefer i7i, i4i, i7ien.  Supported families include m6idn, m6i, m7i, i3en, i4i, i7i, i7ie."
  type        = string
  nullable    = false
}

variable "kms_key_id" {
  description = "OPTIONAL: KMS key ARN for encrypting AWS services like EBS and S3 (immutable after creation). Qumulo encrypts all data independent of AWS default or KMS keys."
  type        = string
  default     = null
  nullable    = true
}

variable "nexus_api_token" {
  description = "OPTIONAL: Qumulo Nexus API token for NeuralProtect"
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}

variable "nexus_registration_key" {
  description = "OPTIONAL: Qumulo Nexus registration key for remote support"
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}

variable "nlb_cross_zone" {
  description = "OPTIONAL: AWS NLB Enable cross-AZ load balancing"
  type        = bool
  default     = false
}

variable "nlb_dns_client_affinity" {
  description = "OPTIONAL: AWS NLB DNS Client Routing Policy Zonal Affinity"
  type        = string
  default     = "availability_zone_affinity"
  validation {
    condition = anytrue([
      var.nlb_dns_client_affinity == "any_availability_zone",
      var.nlb_dns_client_affinity == "availability_zone_affinity",
      var.nlb_dns_client_affinity == "partial_availability_zone_affinity"
    ])
    error_message = "nlb_dns_client_affinity must be set to any_availability_zone, availability_zone_affinity, or partial_availability_zone_affinity."
  }
}

variable "nlb_override_subnet_ids" {
  description = "OPTIONAL: Private Subnet ID(s) for NLB if deploying in subnet(s) other than subnet(s) the cluster is deployed in"
  type        = list(string)
  default     = null
  validation {
    condition     = var.nlb_override_subnet_ids == null || can(regex("^subnet-", var.nlb_override_subnet_ids))
    error_message = "The nlb_override_subnet_ids must be a valid Subnet ID or list of Subnet IDs of the form 'subnet-', or null if deploying in the same subnet(s) as the cluster."
  }
}

variable "nlb_provision" {
  description = "OPTIONAL: Provision an AWS NLB in front of the Qumulo cluster for load balancing and client failover"
  type        = bool
  default     = false
}

variable "nlb_public" {
  description = "OPTIONAL: Makes the NLB for the cluster public, setting this to true will allow anyone to reach the cluster.  Not recommended for production clusters."
  type        = bool
  default     = false
}

variable "nlb_stickiness" {
  description = "OPTIONAL: AWS NLB sticky sessions"
  type        = bool
  default     = true
}

variable "node_count" {
  description = "Number of nodes in the cluster. Valid values: 1 (single node), or 3-24. 1 and 4 not allowed for multi-AZ."
  type        = number
  nullable    = false
}

variable "node_hooks" {
  description = "OPTIONAL: Pre and post userdata hooks for Cluster Nodes."
  type        = map(string)
  default     = null
  nullable    = true
}

variable "np_deletion_protection" {
  description = "OPTIONAL: Causes Terraform to throw an error upon destroy for the NeuralProtect resource.  Safegaurd your NeuralProtect instance.  Set to false to destroy."
  type        = bool
  default     = true
}

variable "np_instance_type" {
  description = "OPTIONAL: NeuralProtect EC2 instance type."
  type        = string
  default     = "m6a.xlarge"
}

variable "np_provision" {
  description = "OPTIOINAL: true/false to enable deployment of the NLB.  If the qconfig module senses multi-AZ it will deploy the NLB in the same subnets as the cluster"
  type        = bool
  default     = false
}

variable "permissions_boundary_arn" {
  description = "OPTIONAL: IAM permissions boundary ARN applied to cluster and provisioner roles"
  type        = string
  default     = null
  nullable    = true
}

variable "provider_timeout_minutes" {
  description = "The total time after which Terraform will abondon the provider deployment of the Qumulo cluster and timeout. In minutes."
  type        = number
  default     = 30
  nullable    = false
}

variable "provisioner_ami_id" {
  description = "OPTIONAL: AMI ID for the provisioner instance. Defaults to Ubunti 24.04 AMI."
  type        = string
  default     = null
  nullable    = true
}

variable "provisioner_hooks" {
  description = "OPTIONAL: Pre and post userdata hooks for the provisioner."
  type        = map(string)
  default     = null
  nullable    = true
}

variable "provisioner_iam_role_arn" {
  type        = string
  default     = null
  nullable    = true
  description = "OPTIONAL: When set, the provider performs no IAM writes for that role — no creation, policy updates, tagging, or deletion — and instead launches instances with your role's instance profile"

  validation {
    condition     = var.provisioner_iam_role_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.provisioner_iam_role_arn))
    error_message = "Must be either null or a valid AWS IAM ARN for the role the provisioner will use."
  }
}

variable "provisioner_instance_type" {
  description = "OPTIONAL: EC2 instance type for the provisioner VM (used during deploy operations). Default: m5.xlarge."
  type        = string
  default     = "m5.xlarge"
  nullable    = false
}

variable "provisioner_security_group_id" {
  description = "OPTIONAL: Bring-your-own security group ID for the provisioner instance. Required together with cluster_security_group_id. See cluster_security_group_id."
  type        = string
  default     = null
  nullable    = true
}

variable "r53_second_subnet_id" {
  description = "OPTIONAL: A second subnet ID, in a unique AZ other than the cluster AZ, for single AZ clusters.  This is then used to build a R53 Resolver to forward traffic to Qumulo DNS for Floating IP resolution."
  type        = string
  default     = null
  validation {
    condition     = var.r53_second_subnet_id == null || can(regex("^subnet-", var.r53_second_subnet_id))
    error_message = "The r53_second_subnet_id must be a valid Subnet ID of the form 'subnet-'."
  }
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  nullable    = false
}

variable "s3_log_bucket_name" {
  description = "OPTIONAL: Bucket name for S3 logging"
  type        = string
  default     = null
  nullable    = true
}

variable "s3_log_bucket_prefix" {
  description = "OPTIONAL: Bucket prefix for S3 logging"
  type        = string
  default     = null
  nullable    = true
}

variable "soft_capacity_limit_tb" {
  description = "OPTIONAL: Soft capacity limit in TB (50 to 50000). Default is 500TB. Can be increased to add storage, but cannot be decreased.  It's like a quota, unused capacity is not billed."
  type        = number
  default     = 500
  nullable    = false
}

variable "storage_class" {
  description = "HOT cluster default is INTELLIGENT_TIERING or STANDARD, COLD cluster default is GLACIER_IR or STANDARD_IA"
  type        = string
  default     = null
  nullable    = true
}

variable "subnet_ids" {
  description = "Subnet IDs for multi-AZ deployment (3+ subnets, one per AZ)"
  type        = list(string)
  nullable    = false
}

variable "tags" {
  description = "OPTIONAL: Tags to apply to all AWS resources created for this cluster."
  type        = map(string)
  default     = null
  nullable    = true
}

variable "vpc_id" {
  description = "VPC ID for the cluster"
  type        = string
  nullable    = false
}

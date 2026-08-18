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

# **** Version 7.4 ****

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_vpc_endpoint" "s3_gateway" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
}

locals {
  #Logic to decide when to provision the NLB
  provision_nlb = var.nlb_provision || length(var.subnet_ids) >= 3

  #Logic to decide when to provision the FIPS
  floating_ip_count    = local.provision_nlb ? 0 : (var.floating_ip_count == 0 ? 0 : (var.node_count > var.floating_ip_count ? var.node_count : var.floating_ip_count))
  floating_ip_count_v4 = var.ip_v4_or_v6 == "v4" ? local.floating_ip_count : null
  floating_ip_count_v6 = var.ip_v4_or_v6 == "v6" ? local.floating_ip_count : null

  #Logic to decide when to provision the R53 Resolver
  provision_resolver = var.r53_second_subnet_id == null || var.cluster_fqdn == null || local.provision_nlb ? false : true

  #Logic to decide when to provision NeuralProtect
  provision_np = var.np_provision
}

#Check for S3 Gateway in VPC
resource "null_resource" "check_s3_gateway" {
  count = data.aws_vpc_endpoint.s3_gateway.vpc_endpoint_type == "Gateway" && data.aws_vpc_endpoint.s3_gateway.state == "available" && length(data.aws_vpc_endpoint.s3_gateway.route_table_ids) > 0 ? 0 : "S3 Gateway not present for the chosen VPC.  Add an S3 Gateway."
}

#This resource reads the AWS Secrets Manager ARN if provided, or accepts a text based admin password.  One or the other must be provided.
#A best practice is to put your password in AWS secrets manager. Note, you will need to update it in Secrets Manager if you change the Admin Password via the Qumulo Core UI/CLI/API.
#Text based password input is treated as sensitive and is provided for environments where another vault solution is being used outside of AWS or for simple test environments.
module "secrets" {
  source = "./modules/secrets"

  admin_pwd_or_secrets_arn = var.admin_pwd_or_secrets_arn
}

#This resource builds the Qumulo Filesystem Cluster consisting of EC2 instances, EBS volumes, and S3 buckets.
#Security groups and IAM roles are built for the cluster and and provisioning instance.
resource "qumulo_filesystem_aws" "cluster" {
  provider = qumulo

  additional_security_group_ids = var.additional_security_group_ids
  admin_password                = module.secrets.resolved_password
  allow_cidrs                   = var.allow_cidrs == null ? [data.aws_vpc.selected.cidr_block] : concat([data.aws_vpc.selected.cidr_block], var.allow_cidrs)
  ami_id                        = var.ami_id
  audit_logging                 = var.audit_logging
  cluster_iam_role_arn          = var.cluster_iam_role_arn
  cluster_fqdn                  = var.cluster_fqdn
  cluster_name                  = var.cluster_name
  cluster_product_type          = var.cluster_product_type
  cluster_security_group_id     = var.cluster_security_group_id
  cluster_version               = var.cluster_version
  deletion_protection           = var.deletion_protection
  deployment_name               = var.deployment_name
  ec2_key_pair                  = var.ec2_key_pair
  floating_ip_count             = local.floating_ip_count_v4
  floating_ip_count_ipv6        = local.floating_ip_count_v6
  instance_type                 = var.instance_type
  kms_key_id                    = var.kms_key_id
  networking_mode               = var.networking_mode
  nexus_registration_key        = var.nexus_registration_key
  node_count                    = var.node_count
  permissions_boundary_arn      = var.permissions_boundary_arn
  provisioner_ami_id            = var.provisioner_ami_id
  provisioner_iam_role_arn      = var.provisioner_iam_role_arn
  provisioner_instance_type     = var.provisioner_instance_type
  provisioner_security_group_id = var.provisioner_security_group_id
  region                        = var.region
  s3_log_bucket_name            = var.s3_log_bucket_name
  s3_log_bucket_prefix          = var.s3_log_bucket_prefix
  storage_class                 = var.storage_class
  soft_capacity_limit_tb        = var.soft_capacity_limit_tb
  subnet_ids                    = var.subnet_ids
  tags                          = var.tags
  vpc_id                        = var.vpc_id

  node_hooks = {
    pre_run  = var.node_hooks_files.pre_run_file == null ? null : file("${path.module}/hooks/${var.node_hooks_files.pre_run_file}")
    post_run = var.node_hooks_files.post_run_file == null ? null : file("${path.module}/hooks/${var.node_hooks_files.post_run_file}")
    override = var.node_hooks_files.override_file == null ? null : file("${path.module}/hooks/${var.node_hooks_files.override_file}")
  }
  provisioner_hooks = {
    pre_run  = var.provisioner_hooks_files.pre_run_file == null ? null : file("${path.module}/hooks/${var.provisioner_hooks_files.pre_run_file}")
    post_run = var.provisioner_hooks_files.post_run_file == null ? null : file("${path.module}/hooks/${var.provisioner_hooks_files.post_run_file}")
    override = var.provisioner_hooks_files.override_file == null ? null : file("${path.module}/hooks/${var.provisioner_hooks_files.override_file}")
  }

  timeouts {
    create = "${tostring(var.provider_timeout_minutes)}m"
    delete = "${tostring(var.provider_timeout_minutes)}m"
    update = "${tostring(var.provider_timeout_minutes)}m"
  }
}

#This module builds a Route 53 Resolver to forward cluster_fqdn DNS requests to the Qumulo cluster.
#The Qumulo cluster will then respond to DNS queries with floating IP addresses for clients to mount, providing load balancing and availability.
#It is only invoked if two private subnets have been provided in unique AZs for availability.
#It is also only applicable to single AZ clusters that are not using a load balancer.
#With this approach floating IP addresses no longer have to be maintained and updated in your chosen DNS solution.
module "route53-resolver" {
  count = local.provision_resolver ? 1 : 0

  source = "./modules/route53-resolver"

  deployment_unique_name = qumulo_filesystem_aws.cluster.deployment_unique_name
  fqdn                   = var.cluster_fqdn
  r53_second_subnet_id   = var.r53_second_subnet_id
  resolver_endpoint_type = var.ip_v4_or_v6 == "v6" ? "DUALSTACK" : "IPV4"
  subnet_id              = var.subnet_ids[0]
  tags                   = var.tags
  target_ips             = qumulo_filesystem_aws.cluster.endpoint_ips == [] ? [qumulo_filesystem_aws.cluster.primary_ips[0]] : slice(qumulo_filesystem_aws.cluster.endpoint_ips, 0, 3)
  vpc_cidr               = var.ip_v4_or_v6 == "v6" ? data.aws_vpc.selected.ipv6_cidr_block : data.aws_vpc.selected.cidr_block
  vpc_id                 = var.vpc_id
}

##This module creates an AWS NLB in front of the Qumulo cluster for load distribution and fault tolerance.
##Floating IPs are disabled when using this module because DNS is no longer used for load distribution
##and floating IPs are no longer relevant for IP failover.  NLBs cost more $ and NFSv3 locking is not
##reliable through an NLB.  An NLB is optional for single AZ deployments and mandatory for multi-AZ
##deployments.
module "nlb" {
  count = local.provision_nlb ? 1 : 0

  source = "./modules/nlb"

  cluster_primary_ips              = qumulo_filesystem_aws.cluster.primary_ips
  cross_zone                       = var.nlb_cross_zone
  deletion_protection              = var.deletion_protection
  deployment_unique_name           = qumulo_filesystem_aws.cluster.deployment_unique_name
  dereg_delay                      = 60
  dereg_term                       = false
  dns_record_client_routing_policy = var.nlb_dns_client_affinity
  ip_address_type                  = var.ip_v4_or_v6 == "v6" ? "dualstack" : "ipv4"
  is_public                        = var.nlb_public
  node_count                       = var.node_count
  override_subnet_ids              = var.nlb_override_subnet_ids
  preserve_ip                      = true
  proxy_proto_v2                   = false
  stickiness                       = var.nlb_stickiness
  subnet_ids                       = var.subnet_ids
  tags                             = var.tags
  vpc_id                           = var.vpc_id
}

##This module creates an AWS instance to run Qumulo NeuralProtect for realtime ransomware dectection.
module "neuralprotect" {
  count = local.provision_np ? 1 : 0

  source = "./modules/neuralprotect"
  providers = {
    qumulo = qumulo.neuralprotect
  }

  additional_security_group_ids = var.additional_security_group_ids
  allow_cidrs                   = var.allow_cidrs
  cluster_admin_password        = module.secrets.resolved_password
  cluster_dns_name              = local.provision_nlb ? module.nlb[0].dns : (local.provision_resolver ? module.route53-resolver[0].dns : null)
  cluster_reference             = qumulo_filesystem_aws.cluster.cluster_reference
  deletion_protection           = var.np_deletion_protection
  instance_type                 = var.np_instance_type
  kms_key_id                    = var.kms_key_id
  permissions_boundary_arn      = var.permissions_boundary_arn
  tags                          = var.tags
}
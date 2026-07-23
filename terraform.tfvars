# ****************************** QUMULO PROVIDER VARIABLES ********************
# *********** AWS Variables ***********
# deployment_name               - A name for this deployment, lower case, 2-36 characters.
# ec2_key_pair                  - Pre-configured EC2 key pair name for SSH access to cluster nodes.
# instance_type                 - EC2 instance type for cluster nodes. i7i, i4i, and i7ie preferred.  Supported families include m6idn, m6i, m7i, i3en, i4i, i7i, i7ie.
# region                        - AWS region for deployment.
# subnet_ids                    - Pre-configured Subnet IDs for cluster nodes.  One subnet ID for single AZ.  Must be 3+ subnets for multi-AZ, each in a distinct availability zone.
# vpc_id                        - Pre-configured VPC ID. Set explicitly in production rather than relying on derivation.
# additional_security_group_ids - (OPTIONAL) Use for adding custom ingress rules beyond those the provider creates ie: ["sg-abc123", "sg-def456"]
# allow_cidrs                   - (OPTIONAL) CIDR blocks allowed to access the cluster (the VPC CIDR is used by default). Production clusters should restrict to known client/management networks. ie: 10.0.1.0/24
# amid_id                       - (OPTIONAL) AMI ID for cluster nodes. If omitted, the default AWS AMI (Ubuntu 24.04) is used. Supports Ubuntu and RHEL 8, 9, and 10 AMIs. See aws-custom-images.md for details.
# cluster_iam_role_arn          - (OPTIONAL) When set, the provider performs no IAM writes for that role — no creation, policy updates, tagging, or deletion — and instead launches instances with your role's instance profile.
# cluster_security_group_id     - (OPTIONAL) Bring-your-own security group ID for cluster nodes. When set, the provider will not create or modify a cluster security group; 
#                                            you must pre-create it in the VPC owner account with the rules documented in the Bring-your-own Security Groups guide. Required together with provisioner_security_group_id. 
#                                            Required for RAM-shared subnets where the consumer account cannot create security groups in the owner's VPC."
# kms_key_id                    - (OPTIONAL) KMS key ARN for encrypting AWS services like EBS and S3 (immutable after creation). Qumulo encrypts all data independent of AWS default or KMS keys.
# provisioner_ami_id            - (OPTIONAL) AMI ID for the provisioner instance. Defaults to Ubunti 24.04 AMI.
# provisioner_iam_role_arn      - (OPTIONAL) When set, the provider performs no IAM writes for that role — no creation, policy updates, tagging, or deletion — and instead launches instances with your role's instance profile.
# provisioner_instance_type     - (OPTIONAL) EC2 instance type for the provisioner VM (used during deploy operations). Default: m5.xlarge.
# provisioner_security_group_id - (OPTIONAL) Bring-your-own security group ID for the provisioner instance. Required together with cluster_security_group_id. See cluster_security_group_id.
# s3_log_bucket_name            - (OPTIONAL) A bucket name to send S3 logs to.
# s3_log_bucket_prefix          - (OPTIONAL) A prefix in the bucket (path) to send S3 logs to.
# permissions_boundary_arn      - (OPTIONAL) IAM permissions boundary ARN applied to the cluster and provisioner roles. The provider attaches the same boundary to both roles it creates.
# tags                          - (OPTIONAL) Tags to apply to all AWS resources created for this cluster.
#subnet_ids    = ["subnet-01d76eb8ccdc3f156", "subnet-0edfe9c88d90d51af", "subnet-0c8edd3974ebe65c2"]

#-----------REQUIRED-------------------
deployment_name = "my-deployment-name"
ec2_key_pair    = "my-key-pair"
instance_type   = "i7i.2xlarge"
region          = "us-west-2"
subnet_ids      = ["subnet-0123456789abcdef1"]
vpc_id          = "vpc-0123456789abcdef1"

#------------OPTIONAL------------------
additional_security_group_ids = null
allow_cidrs                   = null
ami_id                        = null
cluster_iam_role_arn          = null
cluster_security_group_id     = null
kms_key_id                    = null
permissions_boundary_arn      = null
provisioner_ami_id            = null
provisioner_iam_role_arn      = null
provisioner_instance_type     = null
provisioner_security_group_id = null
s3_log_bucket_name            = null
s3_log_bucket_prefix          = null
tags = {
  owner        = "smith"
  department   = "it"
  purpose      = "prod"
}

# ***** Qumulo Cluster Variables ******
# admin_pwd_or_secrets_arn  - The password may be provided as text OR may be pulled from AWS Secrets Manager by referencing the ARN.  Admin password requirements:
#                              8-128 characters long containing at least one uppercase letter, one lowercase letter, and one number or special character. Sensitive -- not stored in Terraform state.
# arn_secrets_manager       - ARN for AWS Secrets Manager where you may reference your cluster's Admin Password.  Sensitive -- not stored in Terraform state.
# cluster_product_type      - Cluster storage product type (immutable after creation). HOT: Optimized for frequently accessed data. COLD: Optimized for archival/infrequently accessed data.
# name                      - Cluster name (2-15 alphanumeric characters). Dash (-) is allowed if not the first or last character. Used as a prefix for AWS resources created for this cluster.
# node_count                - Number of nodes in the cluster. Valid values: 1 (single node), or 3-24. 1 and 4 not allowed for multi-AZ.
# deletion_protection       - Causes Terraform to throw an error upon destroy for the Qumulo Cluster resource.  Safegaurd your cluster.  Default = true.  Set to false to destroy.
# cluster_version           - (OPTIONAL) Qumulo software version. Defaults to latest. Immutable after creation. Upgrade version via cluster UI/API.
# floating_ip_count         - (OPTIONAL) Number of floating IPs. Must be 0, or between 3 and 100. Default=12. NOT applicable with multi-AZ deployments.  
# nexus_registration_key    - (OPTIONAL) Qumulo Nexus registration key for remote support. Obtain from https://nexus.qumulo.com/user/registration-key
# provider_timeout_minutes  - (OPTIONAL) The total time, in minutes, after which Terraform will abondon the provider deployment of the Qumulo cluster and timeout. Default is 30 minutes.
# storage_class             - (OPTIONAL) HOT cluster default is INTELLIGENT_TIERING or override to STANDARD, COLD cluster default is GLACIER_IR or override to STANDARD_IA
# soft_capacity_limit_tb    - (OPTIONAL) Soft capacity limit in TB (50 to 50000). Default is 500TB. Can be increased to add storage, but cannot be decreased.  It's like a quota, unused capacity is not billed.

#-----------REQUIRED-------------------
  admin_pwd_or_secrets_arn = "arn:aws:secretsmanager:us-west-2:<aws account number>:secret:/<secret path>/<secret_name>"
cluster_name             = "CNQ-HOT"
cluster_product_type     = "HOT"
node_count               = 3
deletion_protection      = true

#------------OPTIONAL------------------
cluster_version          = null
floating_ip_count        = 12
nexus_registration_key   = null
provider_timeout_minutes = 30
storage_class            = null
soft_capacity_limit_tb   = 100

# ***** Miscellaneous Variables *******
# If userdata needs to be completely overridden contact support@qumulo.com.  Typically most needs can be accomodated with these pre/post hooks.
# node_hooks        - OPTIONAL: Advanced use only.  Hooks run pre-userdata execution or post-userdata execution.  Executed only on first boot cycle.  See the docs.
# provisioner_hooks - OPTIONAL: Advanced use only.  Hooks run pre-userdata execution or post-userdata execution.  Executed on every boot cycle.  See the docs.
node_hooks = {
  pre_run  = null
  post_run = null
}

provisioner_hooks = {
  pre_run  = null
  post_run = null
}

# ****************************** OPTIONAL MODULES *****************************

# ***** OPTIONAL Route53 Resolver Module *****
# ----- This module builds a Route 53 Resolver to forward cluster_fqdn DNS requests to the Qumulo cluster.
# ----- The Qumulo cluster will then respond to DNS queries with floating IP addresses for clients to mount, providing load balancing and availability.
# ----- It is only invoked if two private subnets have been provided in unique AZs for availability.
# ----- It is also only applicable to single AZ clusters that are not using a load balancer.
# ----- With this approach floating IP addresses no longer have to be maintained and updated in your chosen DNS solution.
#
# cluster_fqdn                    - For Single AZ clusters. A Fully Qualified Domain Name for Qumulo Cluster DNS.  This is only applicable for single AZ clusters with no NLB.
#                                   This may be left 'null' to bypass any FQDN DNS resolution on the Qumulo cluster
# r53_second_subnet_id            - For Single AZ clusters. If you provide a second private subnet in a second unique AZ, a R53 resolver will be configured.
#                                   The resolver will forward the q_cluster_fqdn DNS requests to the Qumulo cluster for DNS resolution of floating IPs. 
#                                   This may be left 'null' to skip R53 Resolver configuration
cluster_fqdn         = null
r53_second_subnet_id = null

# ***** OPTIONAL NLB Module *****
# ----- Disables any R53 Resolver provisioning and floating IPs. Automatically used for multi-AZ deployments.  May be specified for single AZ deployments that require PrivateLink.
#
# nlb_cross_zone                  - true/false to enable cross AZ load balancing.  Only relevant for multi-AZ deployments.
# nlb_override_subnet_ids         - Default = null.  If nlb_provision = true, the NLB will be deployed in the same subnet(s) as the cluster.
#                                       To override enter a list with one subnet for single AZ or three subnets if deploying a multi-AZ distributed cluster
# nlb_provision                   - true/false to enable deployment of the NLB.  If the qconfig module senses multi-AZ it will deploy the NLB in the same subnets as the cluster
# nlb_public                      - Set to true to make the NLB publicly accessible.  Not recommended for produciton deployments.  A firewall should front-end the cluster for public access.
# nlb_stickiness                  - true/false to enable sticky sessions
nlb_cross_zone          = false
nlb_override_subnet_ids = null
nlb_provision           = false
nlb_public              = false
nlb_stickiness          = true

# ***** OPTIONAL NeuralProtect Module *****
# ----- Realtime Ransomware Detection with Qumulo NeuralProtect.  Additional charges apply.
#
# cluster_dns_name                - DNS Name for the cluster.  Leave null to automatically pickup the QDNS or NLB DNS name.
#                                   Ignored if using floating IPs without QDNS
# np_deletion_protection          - Causes Terraform to throw an error upon destroy for the NeuralProtect resource.  Safegaurd your NeuralProtect instance.  Default = true.  Set to false to destroy.
# np_instance_type                - The EC2 instance type for NeuralProtect
# np_provision                    - true/false to enable deployment of the NLB.  If the qconfig module senses multi-AZ it will deploy the NLB in the same subnets as the cluster
# nexus_api_token                 - Qumulo Nexus API token for NeuralProtect.  Required.
cluster_dns_name       = null
np_deletion_protection = false
np_instance_type       = "m6a.xlarge"
np_provision           = false
nexus_api_token        = null
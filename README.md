<!-- BEGIN_TF_DOCS -->

<a target="_blank" href="https://qumulo.com/"><img src="./images/qumulo-scale-anywhere-logo.webp" style="width:150px;height:53px;"></a>

# Deploying Cloud Native Qumulo (CNQ) on AWS with Terraform [![Latest Release](https://img.shields.io/github/release/qumulo/qumulo-terraform-aws.svg)](https://github.com/qumulo/qumulo-terraform-aws/releases)
This repository contains Terraform which deploys S3 buckets and a CNQ cluster with 3 or more instances that adhere to the [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/).
NOTE: as of version 7.0 this Terraform uses the Qumulo AWS Provider.  This greatly simplifies Terraform operations and makes compute elasticity changes even more elegant.  To learn more about the provider read the [provider docs](https://qumulo.github.io/terraform-provider-qumulo-cloud/).

## Configure Terraform backend.tf
This Terraform defaults to store state on S3.  As such the ./backend.tf must both be configured with the S3 bucket and S3 bucket region you choose to store state in.
Note you can't put variables in the backend.tf config, which is why this note is here. If you call this Terraform as a module the backend.tf will be ignored.

## Getting Started with Cloud Native Qumulo (CNQ)
For an overview of CNQ, its reference architecture, and limits, see [How Cloud Native Qumulo Works](https://docs.qumulo.com/aws-administrator-guide/getting-started/how-cloud-native-qumulo-works.html) and for prerequisites and detailed instructions, see [Deploying Cloud Native Qumulo on AWS with Terraform](https://docs.qumulo.com/aws-administrator-guide/getting-started/deploying-instance-terraform.html) on the Documentation Portal.

Qumulo Core >= 7.9.2.1 is required for this Terraform

> ✅ **Tip:** For help with deployment, configuration, updates, scaling out your cluster, and best practices for high performance, [message us on Slack](https://docs.qumulo.com/contacting-qumulo-care-team.html).


---

### Standard Deployment Example

```hcl
module "cloud_native_qumulo" {
  source = "git::https://github.com/Qumulo/qumulo-terraform-aws.git?ref=v7.6"
  # ****************************** QUMULO PROVIDER VARIABLES ********************
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
  ami_parameter_name            = null
  cluster_iam_role_arn          = null
  cluster_security_group_id     = null
  kms_key_id                    = null
  permissions_boundary_arn      = null
  provisioner_iam_role_arn      = null
  provisioner_instance_type     = null
  provisioner_security_group_id = null
  s3_gateway_validation         = null
  s3_log_bucket_name            = null
  s3_log_bucket_prefix          = null
  tags = {
    owner        = "owner"
    department   = "department"
    purpose      = "purpose"
    long_running = "true"
  }

  # ***** Qumulo Cluster Variables ******
  #-----------REQUIRED-------------------
  admin_pwd_or_secrets_arn = "arn:aws:secretsmanager:us-west-2:<aws account number>:secret:/<secret path>/<secret_name>"
  cluster_name             = "CNQ-HOT"
  cluster_product_type     = "HOT"
  deletion_protection      = true
  node_count               = 3

  #------------OPTIONAL------------------
  audit_logging                  = false
  cluster_stall_window_minutes   = 20
  cluster_version                = null
  floating_ip_count              = 12
  ip_v4_or_v6                    = "v4"
  nexus_api_token_or_secrets_arn = null
  node_replacement_when_changed  = null
  provider_timeout_minutes       = 30
  soft_capacity_limit_tb         = null
  storage_class                  = null
}

output "outputs_cloud_native_qumulo" {
  value = module.cloud_native_qumulo
}
```

---

## NeuralSearch (optional)

NeuralSearch is a Qumulo appliance that indexes the files on your cluster and serves a search UI. This module deploys it as a single EC2 VM in the cluster VPC and first subnet. It is off by default. The module uses the `qumulo_neuralsearch_aws` provider resource, which requires Qumulo provider 1.4.19 or later.

### Enable NeuralSearch

Set these variables in `terraform.tfvars` or in your module block.

```hcl
neuralsearch_provision     = true
neuralsearch_allow_cidrs   = null # CIDR blocks allowed to reach the UI on TCP 443. Null allows the cluster VPC CIDR.
neuralsearch_instance_type = null # Null uses the provider default (m6a.4xlarge).
```

Deletion protection follows `deletion_protection`.

### Networking requirements

- The appliance subnet needs outbound HTTPS (for example through a NAT gateway) to `qumulo-neuralsearch.s3.us-west-2.amazonaws.com`, `get.docker.com`, `download.docker.com`, `public.ecr.aws`, the Ubuntu package mirrors, and `ssm.<region>.amazonaws.com` (or an SSM interface endpoint). If any are blocked, the apply waits until `provider_timeout_minutes` expires.
- The appliance must reach the cluster on TCP 8000 and NFS. The default `allow_cidrs` covers this because the VPC CIDR is always included. If you bring your own cluster security group with `cluster_security_group_id`, add these rules yourself.
- The UI listens on TCP 443 at the appliance private IP. Add peered VPC, VPN, or Direct Connect ranges to `neuralsearch_allow_cidrs` to reach it from outside the VPC.

### Cost

The appliance uses a 1 TiB gp3 OS disk provisioned at 80,000 IOPS and 2,000 MiB/s. IOPS and throughput above the gp3 baseline are billed. The default instance type is m6a.4xlarge.

### Access the appliance

The appliance has no public IP. Open a shell through AWS Systems Manager with the `neuralsearch_instance_id` output.

```bash
aws ssm start-session --target <neuralsearch_instance_id> --region <region>
```

### First-boot wizard

1. Open the `neuralsearch_ui_url` output in a browser. Expect a self-signed certificate warning.
2. Enter the cluster REST endpoint, `https://<cluster-ip>:8000`.
3. Enter an API key.
4. Enter the NFS export host. The index lives in the `/.neuralsearch` export.
5. Sign in with a cluster account that holds the Administrators or Observers role.

### Limitations

The `qumulo_neuralsearch_aws` resource does not support `terraform import`.

---

## Terraform Documentation

> ℹ️ **Note:** This repository uses documentation generated with Terraform-Docs.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.32 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1 |
| <a name="requirement_qumulo"></a> [qumulo](#requirement\_qumulo) | >= 1.4.19 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | OPTIONAL: Use for adding custom ingress rules beyond those the provider creates | `list(string)` | `null` | no |
| <a name="input_admin_pwd_or_secrets_arn"></a> [admin\_pwd\_or\_secrets\_arn](#input\_admin\_pwd\_or\_secrets\_arn) | Provide either a plaintext administrator password or an AWS Secrets Manager ARN. | `string` | n/a | yes |
| <a name="input_allow_cidrs"></a> [allow\_cidrs](#input\_allow\_cidrs) | OPTIONAL: CIDR blocks allowed to access the cluster | `list(string)` | `null` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | OPTIONAL: AMI ID for cluster nodes. If omitted, the default Qumulo AMI (Ubuntu 24.04) is used. Supports Ubuntu and RHEL 8, 9, and 10 AMIs. See aws-custom-images.md for details. | `string` | `null` | no |
| <a name="input_ami_parameter_name"></a> [ami\_parameter\_name](#input\_ami\_parameter\_name) | OPTIONAL: AWS Systems Manager Parameter Store parameter name to lookup the AMI. Takes priority over ami\_id if provided. | `string` | `null` | no |
| <a name="input_audit_logging"></a> [audit\_logging](#input\_audit\_logging) | OPTIONAL: Send Qumulo audit logs to AWS CloudWatch logs. | `bool` | `false` | no |
| <a name="input_cluster_dns_name"></a> [cluster\_dns\_name](#input\_cluster\_dns\_name) | OPTIONAL: DNS Name for the cluster.  Leave null to automatically pickup the QDNS or NLB DNS name. | `string` | `null` | no |
| <a name="input_cluster_fqdn"></a> [cluster\_fqdn](#input\_cluster\_fqdn) | OPTIONAL: Fully qualified domain name for Qumulo DNS | `string` | `null` | no |
| <a name="input_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#input\_cluster\_iam\_role\_arn) | OPTIONAL: When set, the provider performs no IAM writes for that role — no creation, policy updates, tagging, or deletion — and instead launches instances with your role's instance profile | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name (2-15 alphanumeric characters). Used as a prefix for AWS resources created for this cluster. | `string` | n/a | yes |
| <a name="input_cluster_product_type"></a> [cluster\_product\_type](#input\_cluster\_product\_type) | Cluster storage product type (immutable after creation). HOT: Optimized for frequently accessed data. COLD: Optimized for archival/infrequently accessed data. | `string` | n/a | yes |
| <a name="input_cluster_security_group_id"></a> [cluster\_security\_group\_id](#input\_cluster\_security\_group\_id) | OPTIONAL: Bring-your-own security group ID for cluster nodes. When set, the provider will not create or modify a cluster security group; you must pre-create it in the VPC owner account with the rules documented in the Bring-your-own Security Groups guide. Required together with provisioner\_security\_group\_id. Required for RAM-shared subnets where the consumer account cannot create security groups in the owner's VPC. | `string` | `null` | no |
| <a name="input_cluster_stall_window_minutes"></a> [cluster\_stall\_window\_minutes](#input\_cluster\_stall\_window\_minutes) | OPTIONAL: The time after which Terraform will abondon the provider deployment if the Qumulo cluster is not progressing with the deployment. In minutes. | `number` | `20` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | OPTIONAL: Qumulo software version. Defaults to latest. Immutable after creation. Upgrade version via cluster UI/API. | `string` | `null` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Enables EC2 Termination protection and prevents Terraform from destroying non-empty S3 Buckets | `bool` | `true` | no |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | Cluster name (2-15 alphanumeric characters). Used as a prefix for AWS resources created for this cluster. | `string` | n/a | yes |
| <a name="input_ec2_key_pair"></a> [ec2\_key\_pair](#input\_ec2\_key\_pair) | EC2 key pair name for SSH access to cluster nodes | `string` | n/a | yes |
| <a name="input_floating_ip_count"></a> [floating\_ip\_count](#input\_floating\_ip\_count) | OPTIONAL: Number of floating IPs. Must be 0, or between 3 and 100. NOT applicable with multi-AZ deployments. | `number` | `12` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type for the cluster. Prefer i7i, i4i, i7ien.  Supported families include m6idn, m6i, m7i, i3en, i4i, i7i, i7ie. | `string` | n/a | yes |
| <a name="input_ip_v4_or_v6"></a> [ip\_v4\_or\_v6](#input\_ip\_v4\_or\_v6) | OPTIONAL: Only change this from default (v4) if connecting to the cluster via IPv6.  Not supported for clusters deployed without the Qumulo Terraform Provider. | `string` | `"v4"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | OPTIONAL: KMS key ARN for encrypting AWS services like EBS and S3 (immutable after creation). Qumulo encrypts all data independent of AWS default or KMS keys. | `string` | `null` | no |
| <a name="input_networking_mode"></a> [networking\_mode](#input\_networking\_mode) | OPTIONAL: Only change this from default (host\_managed) if importing a cluster that was deployed without the Qumulo Terraform Provider.  Terraform versions prior to 7.0. | `string` | `"host_managed"` | no |
| <a name="input_neuralsearch_allow_cidrs"></a> [neuralsearch\_allow\_cidrs](#input\_neuralsearch\_allow\_cidrs) | OPTIONAL: CIDR blocks allowed to reach the NeuralSearch UI on TCP 443. Defaults to the cluster VPC CIDR. Add peered VPC, VPN, or Direct Connect ranges here. | `list(string)` | `null` | no |
| <a name="input_neuralsearch_instance_type"></a> [neuralsearch\_instance\_type](#input\_neuralsearch\_instance\_type) | OPTIONAL: NeuralSearch EC2 instance type. Null uses the provider default (m6a.4xlarge). | `string` | `null` | no |
| <a name="input_neuralsearch_provision"></a> [neuralsearch\_provision](#input\_neuralsearch\_provision) | OPTIONAL: true/false to enable deployment of the NeuralSearch appliance. | `bool` | `false` | no |
| <a name="input_nexus_api_token_or_secrets_arn"></a> [nexus\_api\_token\_or\_secrets\_arn](#input\_nexus\_api\_token\_or\_secrets\_arn) | OPTIONAL: Provide either a plaintext Nexus API token or an AWS Secrets Manager ARN for the token. | `string` | `null` | no |
| <a name="input_nlb_cross_zone"></a> [nlb\_cross\_zone](#input\_nlb\_cross\_zone) | OPTIONAL: AWS NLB Enable cross-AZ load balancing | `bool` | `false` | no |
| <a name="input_nlb_deletion_protection"></a> [nlb\_deletion\_protection](#input\_nlb\_deletion\_protection) | Enables NLB Termination protection and prevents Terraform from destroying the NLB | `bool` | `true` | no |
| <a name="input_nlb_dns_client_affinity"></a> [nlb\_dns\_client\_affinity](#input\_nlb\_dns\_client\_affinity) | OPTIONAL: AWS NLB DNS Client Routing Policy Zonal Affinity | `string` | `"availability_zone_affinity"` | no |
| <a name="input_nlb_override_subnet_ids"></a> [nlb\_override\_subnet\_ids](#input\_nlb\_override\_subnet\_ids) | OPTIONAL: Private Subnet ID(s) for NLB if deploying in subnet(s) other than subnet(s) the cluster is deployed in | `list(string)` | `null` | no |
| <a name="input_nlb_provision"></a> [nlb\_provision](#input\_nlb\_provision) | OPTIONAL: Provision an AWS NLB in front of the Qumulo cluster for load balancing and client failover | `bool` | `false` | no |
| <a name="input_nlb_public"></a> [nlb\_public](#input\_nlb\_public) | OPTIONAL: Makes the NLB for the cluster public, setting this to true will allow anyone to reach the cluster.  Not recommended for production clusters. | `bool` | `false` | no |
| <a name="input_nlb_stickiness"></a> [nlb\_stickiness](#input\_nlb\_stickiness) | OPTIONAL: AWS NLB sticky sessions | `bool` | `true` | no |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Number of nodes in the cluster. Valid values: 1 (single node), or 3-24. 1 and 4 not allowed for multi-AZ. | `number` | n/a | yes |
| <a name="input_node_hooks_files"></a> [node\_hooks\_files](#input\_node\_hooks\_files) | OPTIONAL: Pre and post userdata hooks files for Cluster Nodes. | `map(string)` | `null` | no |
| <a name="input_node_replacement_when_changed"></a> [node\_replacement\_when\_changed](#input\_node\_replacement\_when\_changed) | OPTIONAL: Changing the random string will trigger a node replacement with the same EC2 instance type. A typical use case would be to put in yyyy-mm-dd that you trigger a replace. | `string` | `null` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | OPTIONAL: IAM permissions boundary ARN applied to cluster and provisioner roles | `string` | `null` | no |
| <a name="input_provider_timeout_minutes"></a> [provider\_timeout\_minutes](#input\_provider\_timeout\_minutes) | The total time after which Terraform will abondon the provider deployment of the Qumulo cluster and timeout. In minutes. | `number` | `30` | no |
| <a name="input_provisioner_hooks_files"></a> [provisioner\_hooks\_files](#input\_provisioner\_hooks\_files) | OPTIONAL: Pre and post userdata hooks files for the provisioner. | `map(string)` | `null` | no |
| <a name="input_provisioner_iam_role_arn"></a> [provisioner\_iam\_role\_arn](#input\_provisioner\_iam\_role\_arn) | OPTIONAL: When set, the provider performs no IAM writes for that role — no creation, policy updates, tagging, or deletion — and instead launches instances with your role's instance profile | `string` | `null` | no |
| <a name="input_provisioner_instance_type"></a> [provisioner\_instance\_type](#input\_provisioner\_instance\_type) | OPTIONAL: EC2 instance type for the provisioner VM (used during deploy operations). Default: m5.xlarge. | `string` | `"m5.xlarge"` | no |
| <a name="input_provisioner_security_group_id"></a> [provisioner\_security\_group\_id](#input\_provisioner\_security\_group\_id) | OPTIONAL: Bring-your-own security group ID for the provisioner instance. Required together with cluster\_security\_group\_id. See cluster\_security\_group\_id. | `string` | `null` | no |
| <a name="input_r53_second_subnet_id"></a> [r53\_second\_subnet\_id](#input\_r53\_second\_subnet\_id) | OPTIONAL: A second subnet ID, in a unique AZ other than the cluster AZ, for single AZ clusters.  This is then used to build a R53 Resolver to forward traffic to Qumulo DNS for Floating IP resolution. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for deployment | `string` | n/a | yes |
| <a name="input_s3_gateway_validation"></a> [s3\_gateway\_validation](#input\_s3\_gateway\_validation) | OPTIONAL: Terraform will test for an S3 gateway if this is left at null or set to true.  Set to false for environments that have complex VPC networking. | `bool` | `null` | no |
| <a name="input_s3_log_bucket_name"></a> [s3\_log\_bucket\_name](#input\_s3\_log\_bucket\_name) | OPTIONAL: Bucket name for S3 logging | `string` | `null` | no |
| <a name="input_s3_log_bucket_prefix"></a> [s3\_log\_bucket\_prefix](#input\_s3\_log\_bucket\_prefix) | OPTIONAL: Bucket prefix for S3 logging | `string` | `null` | no |
| <a name="input_soft_capacity_limit_tb"></a> [soft\_capacity\_limit\_tb](#input\_soft\_capacity\_limit\_tb) | OPTIONAL: Soft capacity limit in TB (50 to 50000). Default is 500TB. Can be increased to add storage, but cannot be decreased.  It's like a quota, unused capacity is not billed. | `number` | `500` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | HOT cluster default is INTELLIGENT\_TIERING or STANDARD, COLD cluster default is GLACIER\_IR or STANDARD\_IA | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet ID for a single AZ deployment or 3+ subnets, one per AZ, for a multi-AZ deployment) | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | OPTIONAL: Tags to apply to all AWS resources created for this cluster. | `map(string)` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for the cluster | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the Qumulo cluster |
| <a name="output_cluster_soft_capacity_limit_tb"></a> [cluster\_soft\_capacity\_limit\_tb](#output\_cluster\_soft\_capacity\_limit\_tb) | Total capacity the cluster may consume.  Only used capacity is billed. |
| <a name="output_cluster_uuid"></a> [cluster\_uuid](#output\_cluster\_uuid) | UUID of the Qumulo cluster |
| <a name="output_deployment_unique_name"></a> [deployment\_unique\_name](#output\_deployment\_unique\_name) | Unique deployment identifier |
| <a name="output_endpoint_ips"></a> [endpoint\_ips](#output\_endpoint\_ips) | Client-facing IPs. Floating IPs if configured, otherwise primary IPs. |
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Connection endpoints for various protocols |
| <a name="output_neuralsearch_instance_id"></a> [neuralsearch\_instance\_id](#output\_neuralsearch\_instance\_id) | EC2 instance ID of the NeuralSearch appliance. Use with aws ssm start-session --target. Null when NeuralSearch is not provisioned. |
| <a name="output_neuralsearch_private_ip"></a> [neuralsearch\_private\_ip](#output\_neuralsearch\_private\_ip) | Private IP address of the NeuralSearch appliance. Null when NeuralSearch is not provisioned. |
| <a name="output_neuralsearch_ui_url"></a> [neuralsearch\_ui\_url](#output\_neuralsearch\_ui\_url) | URL of the NeuralSearch web UI. Null when NeuralSearch is not provisioned. |
| <a name="output_primary_ips"></a> [primary\_ips](#output\_primary\_ips) | Per-node primary IPs. Use these directly when no floating IPs are configured, or for per-node access. |
| <a name="output_provisioner_log"></a> [provisioner\_log](#output\_provisioner\_log) | CloudWatch Log for the provisioner |

---

## About This Repository
This repository uses the [MIT license](LICENSE). All contents Copyright &copy; 2024 [Qumulo, Inc.](https://qumulo.com), except where specified. All trademarks are property of their respective owners.

For more information about this repository, contact [Dack Busch](https://github.com/dackbusch) and [Gokul Kupparaj](https://github.com/gokulku).
<!-- END_TF_DOCS -->
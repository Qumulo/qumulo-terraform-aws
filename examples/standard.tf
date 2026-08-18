module "cloud_native_qumulo" {
  source = "git::https://github.com/Qumulo/aws-terraform-cnq.git?ref=v7.4"
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
  audit_logging            = false
  cluster_version          = null
  floating_ip_count        = 12
  ip_v4_or_v6              = "v4"  
  nexus_registration_key   = null
  provider_timeout_minutes = 30
  soft_capacity_limit_tb   = null
  storage_class            = null  
}

output "outputs_cloud_native_qumulo" {
  value = module.cloud_native_qumulo
}

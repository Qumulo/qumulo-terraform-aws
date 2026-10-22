mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "10.0.0.0/16"
    }
  }
}

mock_provider "null" {}

mock_provider "random" {}

mock_provider "qumulo" {}

variables {
  admin_pwd_or_secrets_arn = "Passw0rd!Example"
  cluster_name             = "CNQ-HOT"
  cluster_product_type     = "HOT"
  deletion_protection      = true
  deployment_name          = "my-deployment-name"
  ec2_key_pair             = "my-key-pair"
  instance_type            = "i7i.2xlarge"
  node_count               = 3
  region                   = "us-west-2"
  s3_gateway_validation    = false
  subnet_ids               = ["subnet-0123456789abcdef1"]
  vpc_id                   = "vpc-0123456789abcdef1"
}

run "neuralsearch_disabled_by_default" {
  command = plan

  assert {
    condition     = length(qumulo_neuralsearch_aws.search) == 0
    error_message = "NeuralSearch must not be provisioned unless neuralsearch_provision is true."
  }
}

run "neuralsearch_enabled" {
  command = plan

  variables {
    neuralsearch_provision = true
  }

  assert {
    condition     = length(qumulo_neuralsearch_aws.search) == 1
    error_message = "NeuralSearch must be provisioned when neuralsearch_provision is true."
  }

  assert {
    condition     = qumulo_neuralsearch_aws.search[0].deletion_protection == var.deletion_protection
    error_message = "NeuralSearch deletion_protection must follow var.deletion_protection."
  }
}

run "neuralsearch_deletion_protection_disabled" {
  command = plan

  variables {
    deletion_protection    = false
    neuralsearch_provision = true
  }

  assert {
    condition     = qumulo_neuralsearch_aws.search[0].deletion_protection == false
    error_message = "NeuralSearch deletion_protection must be false when var.deletion_protection is false."
  }
}

run "neuralsearch_allow_cidrs_passed_through" {
  command = plan

  variables {
    neuralsearch_allow_cidrs = ["10.20.0.0/16"]
    neuralsearch_provision   = true
  }

  assert {
    condition     = tolist(qumulo_neuralsearch_aws.search[0].allow_cidrs) == tolist(["10.20.0.0/16"])
    error_message = "neuralsearch_allow_cidrs must be passed to the NeuralSearch resource unchanged."
  }
}

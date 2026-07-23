# =============================================================================
# BACKEND CONFIGURATION
# =============================================================================
# S3 Backend (Default)
# -----------------------------------------------------------------------------
# Comment out this entire block to use local backend instead
terraform {
  backend "s3" {
    bucket               = "my-bucket-for-state"
    key                  = "tf-state/cnq/terraform.tfstate"
    region               = "us-west-2"
    use_lockfile         = true
    workspace_key_prefix = "tf-state-workspace"
  }
}


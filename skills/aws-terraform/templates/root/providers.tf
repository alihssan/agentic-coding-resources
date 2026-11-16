# Provider blocks live only in the root config (rule B4).
# No `profile` and no keys here: people use `AWS_PROFILE=<name>`, CI uses OIDC (rule S5).

provider "aws" {
  region = var.region

  # Stop before any change if the credentials belong to another account (rule S4).
  allowed_account_ids = [var.account_id]

  # Shared tags, once. Resources set only Name (rule R4).
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
    }
  }
}

# A second account (for example shared DNS) needs its own aliased provider with a role.
# provider "aws" {
#   alias               = "network"
#   region              = var.region
#   allowed_account_ids = ["<NETWORK_ACCOUNT_ID>"]
#   assume_role {
#     role_arn     = "arn:aws:iam::<NETWORK_ACCOUNT_ID>:role/<TERRAFORM_ROLE>"
#     session_name = "terraform-${var.environment}"
#   }
# }

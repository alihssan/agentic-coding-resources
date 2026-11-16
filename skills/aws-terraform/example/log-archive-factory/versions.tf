terraform {
  required_version = ">= 1.11"

  # The factory has no aws resources of its own, but it must still declare the provider:
  # without this, `mock_provider "aws"` in tests/ does not reach the child module, and
  # `terraform test` uses REAL AWS credentials (rule F8).
  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

terraform {
  # 1.11+: S3 native state locking and write-only arguments.
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Root config: an upper bound, so a new major is never installed without review.
      # The committed .terraform.lock.hcl pins the exact version (rule V2).
      version = "~> 6.0"
    }
  }
}

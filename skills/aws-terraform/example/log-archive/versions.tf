terraform {
  # Write-only arguments need 1.11. A reusable module sets a floor only (rule V1).
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

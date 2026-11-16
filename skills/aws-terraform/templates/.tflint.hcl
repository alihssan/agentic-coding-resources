# tflint for AWS Terraform. Copy to the repo root. scripts/check-terraform.sh passes it to
# every directory, and runs `tflint --init` to download the plugins.

config {
  # Also lint the modules this config calls from local paths.
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Catches invalid instance types, engine versions, regions and more, at lint time.
# Check for a newer version: https://github.com/terraform-linters/tflint-ruleset-aws/releases
plugin "aws" {
  enabled = true
  version = "0.50.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Rules beyond the "recommended" preset (rules I1, L1, V1 in references/rules.md).
rule "terraform_documented_variables" { enabled = true }
rule "terraform_documented_outputs" { enabled = true }
rule "terraform_naming_convention" { enabled = true }
rule "terraform_standard_module_structure" { enabled = true }
rule "terraform_comment_syntax" { enabled = true }
rule "terraform_unused_required_providers" { enabled = true }

# Unit tests: mocked AWS provider, plan only, no credentials, seconds to run (rule Q2).
# Run: terraform test -filter=tests/unit.tftest.hcl
# A full working example: ../../example/log-archive/tests/unit.tftest.hcl
#
# One run per rule the code enforces:
#   - each validation block       -> a run with a bad value and expect_failures = [var.<name>]
#   - each precondition           -> a run that breaks it and expect_failures = [<resource address>]
#   - each safe default           -> an assert on the planned attribute
#   - create = false              -> an assert that nothing is planned and outputs are null

mock_provider "aws" {
  # Values the code reads at plan time must be real-shaped, or functions on them fail.
  # mock_resource "aws_s3_bucket" {
  #   defaults = { arn = "arn:aws:s3:::example" }
  # }
  # mock_data "aws_caller_identity" {
  #   defaults = { account_id = "111122223333" }
  # }
  # Terraform >= 1.17: mock_ephemeral "aws_secretsmanager_secret_version" {
  #   defaults = { secret_string = "not-a-real-secret" }
  # }
}

variables {
  # <REQUIRED_INPUT> = "<VALID_VALUE>"
}

run "safe_defaults" {
  command = plan

  # assert {
  #   condition     = aws_db_instance.this[0].deletion_protection == true
  #   error_message = "deletion_protection must default to true."
  # }
}

# run "rejects_<bad_input>" {
#   command = plan
#   variables {
#     <INPUT> = "<BAD_VALUE>"
#   }
#   expect_failures = [var.<INPUT>]
# }

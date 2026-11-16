# Unit tests: mocked provider, plan only, no AWS credentials (rule Q2).
# Run: terraform test -filter=tests/unit.tftest.hcl

mock_provider "aws" {
  # The policy document reads the bucket ARN, so the mock must return a real-shaped one.
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::example-logs"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  name        = "example-logs"
  kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/00000000-0000-0000-0000-000000000000"
}

run "safe_defaults" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this[0].force_destroy == false
    error_message = "force_destroy must default to false."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this[0].restrict_public_buckets
    error_message = "Public access must be blocked."
  }

  assert {
    condition     = aws_s3_bucket_versioning.this[0].versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be on."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this[0].rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "Logs must be encrypted with KMS."
  }
}

run "create_false_makes_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = length(aws_s3_bucket.this) == 0 && output.bucket_arn == null
    error_message = "create = false must plan no resources and return null outputs."
  }
}

run "rejects_uppercase_name" {
  command = plan

  variables {
    name = "Example_Logs"
  }

  expect_failures = [var.name]
}

run "rejects_non_kms_arn" {
  command = plan

  variables {
    kms_key_arn = "alias/aws/s3"
  }

  expect_failures = [var.kms_key_arn]
}

run "rejects_fractional_retention" {
  command = plan

  variables {
    retention_days = 30.5
  }

  expect_failures = [var.retention_days]
}

run "rejects_transition_after_expiry" {
  command = plan

  variables {
    retention_days             = 30
    transition_to_glacier_days = 60
  }

  expect_failures = [aws_s3_bucket.this]
}

run "allows_no_transition" {
  command = plan

  variables {
    transition_to_glacier_days = null
  }

  assert {
    condition     = length(one(aws_s3_bucket_lifecycle_configuration.this[0].rule).transition) == 0
    error_message = "A null transition must plan no transition block."
  }
}

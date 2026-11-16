# Factory tests (rule F7): instance count, default merge, key validation, empty map.
# Run: terraform test -filter=tests/unit.tftest.hcl

mock_provider "aws" {
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
  name_prefix = "acme-prod-logs"
  defaults = {
    kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  }
  archives = {
    alb = {}
    cloudtrail = {
      retention_days             = 2555
      transition_to_glacier_days = 30
      tags                       = { DataClass = "audit" }
    }
  }
}

run "one_instance_per_key" {
  command = plan

  assert {
    condition     = length(module.archive) == 2 && contains(keys(module.archive), "alb") && contains(keys(module.archive), "cloudtrail")
    error_message = "Each archives key must plan exactly one module instance."
  }

  assert {
    condition     = local.archives["alb"].name == "acme-prod-logs-alb"
    error_message = "Bucket name must be <name_prefix>-<key>."
  }
}

run "defaults_apply_and_items_override" {
  command = plan

  assert {
    condition     = local.archives["alb"].retention_days == 365 && local.archives["alb"].transition_to_glacier_days == 90
    error_message = "An item with no settings must take the defaults."
  }

  assert {
    condition     = local.archives["cloudtrail"].retention_days == 2555 && local.archives["cloudtrail"].transition_to_glacier_days == 30
    error_message = "An item's own settings must win over the defaults."
  }
}

run "rejects_bad_key" {
  command = plan

  variables {
    archives = {
      "Bad_Key" = {}
    }
  }

  expect_failures = [var.archives]
}

run "empty_map_plans_nothing" {
  command = plan

  variables {
    archives = {}
  }

  assert {
    condition     = length(module.archive) == 0 && length(output.bucket_arns) == 0
    error_message = "An empty map must plan no archives."
  }
}

# The child's own rules (name format, transition before expiry) are tested in
# ../log-archive/tests. expect_failures cannot point into a child module, so they are not
# repeated here (rule F7).

# Factory pattern (rules F1-F7): one map of specs in, one module instance per key out.
# The child module (../log-archive) stays a normal, tested module. This file adds only
# the merge of defaults and the loop (rule F4).

locals {
  # Explicit merge, no try() chains: a misspelled attribute fails at plan (rule F3).
  archives = {
    for key, item in var.archives : key => {
      name                       = "${var.name_prefix}-${key}"
      retention_days             = coalesce(item.retention_days, var.defaults.retention_days)
      transition_to_glacier_days = item.transition_to_glacier_days != null ? item.transition_to_glacier_days : var.defaults.transition_to_glacier_days
      kms_key_arn                = coalesce(item.kms_key_arn, var.defaults.kms_key_arn)
      tags                       = item.tags
    }
  }
}

module "archive" {
  source   = "../log-archive"
  for_each = local.archives

  name                       = each.value.name
  retention_days             = each.value.retention_days
  transition_to_glacier_days = each.value.transition_to_glacier_days
  kms_key_arn                = each.value.kms_key_arn
  tags                       = each.value.tags
}

# Factory input (rules F2, F3): one map, keyed by a stable human name. The key becomes the
# address module.archive["<key>"], so renaming a key replaces that bucket.

variable "archives" {
  description = "Log archives to create, keyed by a short stable name (lowercase, digits, hyphens). The bucket name is <name_prefix>-<key>."
  type = map(object({
    retention_days             = optional(number)
    transition_to_glacier_days = optional(number)
    kms_key_arn                = optional(string)
    tags                       = optional(map(string), {})
  }))
  nullable = false

  validation {
    condition     = alltrue([for k in keys(var.archives) : can(regex("^[a-z0-9][a-z0-9-]{0,30}[a-z0-9]$", k))])
    error_message = "Each archives key must be 2 to 32 characters: lowercase letters, digits and hyphens, starting and ending with a letter or digit."
  }
}

# Values every archive in this environment shares, unless the item sets its own (rule F3).
variable "defaults" {
  description = "Shared settings for every archive. An item's own value wins."
  type = object({
    retention_days             = optional(number, 365)
    transition_to_glacier_days = optional(number, 90)
    kms_key_arn                = string
  })
  nullable = false
}

variable "name_prefix" {
  description = "Prefix for every bucket name, for example acme-prod-logs."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,28}$", var.name_prefix))
    error_message = "name_prefix must be 2 to 29 characters: lowercase letters, digits and hyphens."
  }
}

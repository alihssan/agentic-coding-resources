variable "create" {
  description = "Whether to create any resources. Setting this to false destroys everything this module created."
  type        = bool
  default     = true
  nullable    = false
}

variable "name" {
  description = "Bucket name. Lowercase letters, digits, dots and hyphens, 3 to 63 characters."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 63 characters: lowercase letters, digits, dots and hyphens, starting and ending with a letter or digit."
  }
}

variable "kms_key_arn" {
  description = "ARN of the customer managed KMS key that encrypts the logs."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/", var.kms_key_arn))
    error_message = "kms_key_arn must be a KMS key ARN, for example arn:aws:kms:us-east-1:111122223333:key/<id>."
  }
}

variable "retention_days" {
  description = "Days to keep log objects before they expire. 1 to 3650."
  type        = number
  default     = 365
  nullable    = false

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 3650 && floor(var.retention_days) == var.retention_days
    error_message = "retention_days must be a whole number from 1 to 3650."
  }
}

variable "transition_to_glacier_days" {
  description = "Days before log objects move to Glacier Flexible Retrieval. Null keeps them in Standard. Must be less than retention_days."
  type        = number
  default     = 90
}

variable "enable_force_destroy" {
  description = "Allow Terraform to delete the bucket while it still holds logs. Keep false outside test accounts."
  type        = bool
  default     = false
  nullable    = false
}

variable "tags" {
  description = "Extra tags for the bucket. Shared tags belong in the provider default_tags."
  type        = map(string)
  default     = {}
  nullable    = false
}

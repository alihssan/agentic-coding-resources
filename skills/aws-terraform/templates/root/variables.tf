variable "region" {
  description = "Default AWS Region for this environment."
  type        = string
  nullable    = false
}

variable "account_id" {
  description = "The only AWS account ID this environment may change."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be 12 digits."
  }
}

variable "environment" {
  description = "Environment name, for example dev, test or prod."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test or prod."
  }
}

variable "project" {
  description = "Project tag value."
  type        = string
  nullable    = false
}

variable "owner" {
  description = "Owner tag value: the team that answers for these resources."
  type        = string
  nullable    = false
}

variable "cost_center" {
  description = "CostCenter tag value."
  type        = string
  nullable    = false
}

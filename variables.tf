variable "bucket_suffix" {
  type        = bool
  description = "Adds a random suffix to the bucket name."
  default     = false
}

variable "cloudwatch_log_retention" {
  type        = number
  description = "Number of days to retain logs in CloudWatch."
  default     = 30
}

variable "environment" {
  type        = string
  description = "Environment for the deployment."
  default     = "dev"
}

variable "key_recovery_period" {
  type        = number
  default     = 30
  description = "Recovery period for deleted KMS keys in days. Must be between 7 and 30."

  validation {
    condition     = var.key_recovery_period > 6 && var.key_recovery_period < 31
    error_message = "Recovery period must be between 7 and 30."
  }
}

variable "log_groups" {
  type = map(object({
    name      = optional(string, "")
    class     = optional(string, "STANDARD")
    retention = optional(number, null)
    tags      = optional(map(string), {})
  }))
  description = "List of CloudWatch log groups to create."
  default     = {}
}

variable "log_groups_to_datadog" {
  type        = bool
  description = "Send CloudWatch logs to Datadog. The Datadog forwarder must have already been deployed."
  default     = true
}

variable "object_lock_mode" {
  type        = string
  description = "Object lock mode for the bucket."
  default     = "GOVERNANCE"

  validation {
    condition = contains([
      "COMPLIANCE",
      "DISABLED",
      "GOVERNANCE"
    ], var.object_lock_mode)
    error_message = "Valid object lock modes are: COMPLIANCE, DISABLED, GOVERNANCE."
  }
}

variable "object_lock_period" {
  type        = string
  description = "Period for which objects are locked. Valid values are days or years."
  default     = "days"

  validation {
    condition = contains([
      "days",
      "years"
    ], var.object_lock_mode)
    error_message = "Valid object lock periods are: days, years."
  }
}

variable "object_lock_retention" {
  type        = number
  description = "Retention age based on the lock period."
  default     = 30
}

variable "project" {
  type        = string
  description = "Project that these resources are supporting."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}

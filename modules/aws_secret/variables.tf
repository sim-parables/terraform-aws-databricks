## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "kms_key_id" {
  type        = string
  description = "Existing AWS KMS Key ID"
}

variable "secret_name" {
  type        = string
  description = "AWS Secret Name"
}

variable "secret_value" {
  type        = string
  description = "AWS Secret Value"
  sensitive   = true
}

variable "administrator_arn" {
  type        = string
  description = "AWS CLI Administrator ARN"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "secret_description" {
  type        = string
  description = "AWS Secret Description"
  default     = null
}

variable "recovery_window_in_days" {
  type        = number
  description = "Recovery Window incase of Secret Deletion. Default to 0 for no Recovery Window"
  default     = 0
}

variable "tags" {
  type        = map(string)
  description = "AWS Resource Tag(s)"
  default     = {}
}
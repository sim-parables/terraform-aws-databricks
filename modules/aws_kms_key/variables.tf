## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "kms_key_name" {
  type        = string
  description = "AWS KMS Key Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "kms_retention_days" {
  type        = number
  description = "AWS Key Retention in Days"
  default     = 10
}

variable "tags" {
  type        = map(string)
  description = "AWS Resource Tag(s)"
  default     = {}
}
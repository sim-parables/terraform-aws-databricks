## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "aws_vpc_name" {
  type        = string
  description = "AWS VPC Name"
  default     = null
}

variable "cidr_block" {
  type        = string
  description = "Virtual Internal IP Address Block Range"
  default     = "10.4.0.0/16"
}

variable "tags" {
  type        = map(string)
  description = "AWS Resource Tag(s)"
  default     = {}
}
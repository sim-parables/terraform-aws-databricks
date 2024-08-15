## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

variable "aws_bucket_name" {
  type        = string
  description = "AWS Bucket Name for Databricks Accounts"
}

variable "aws_kms_key_arn" {
  type        = string
  description = "AWS Bucket Name for Databricks Accounts"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_storage_configuration_name" {
  type        = string
  description = "Databricks Storage Configration Name for AWS S3 Bucket"
  default     = "s3-databricks-storage-config"
}

variable "tags" {
  type        = map(string)
  description = "AWS Resource Tag(s)"
  default     = {}
}
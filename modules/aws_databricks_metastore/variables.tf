## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "DATABRICKS_ACCOUNT_ID" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

variable "DATABRICKS_ADMINISTRATOR" {
  type        = string
  description = "Email Adress for the Databricks Unity Catalog Administrator"
}

variable "aws_s3_bucket_name" {
  type        = string
  description = "AWS S3 Bucket Name for Databricks MWS and Unity Catalog"
}

variable "aws_s3_bucket_arn" {
  type        = string
  description = "AWS S3 Bucket ARN for Databricks MWS and Unity Catalog"
}

variable "aws_kms_key_arn" {
  type        = string
  description = "AWS Bucket Name for Databricks Accounts"
}

variable "databricks_storage_name" {
  type        = string
  description = "Databricks Workspace Storage Name"
}

variable "databricks_workspace_number" {
  type        = number
  description = "Databricks Workspace ID (Number Only)"
}

variable "databricks_metastore_grants" {
  description = "List of Databricks Metastore Grant Mappings"
  type        = list(string)
}

variable "databricks_catalog_grants" {
  description = "List of Databricks Unity Catalog Grant Mappings"
  type        = list(string)
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_service_principal_name" {
  type        = string
  description = "Databricks Service Principal Name"
  default     = "databricks-service-principal"
}

variable "databricks_service_principal_token_seconds" {
  type        = number
  description = "Databricks Service Principal Token Lifetime in Seconds"
  default     = 3600
}

variable "databricks_catalog_name" {
  type        = string
  description = "Databricks Catalog Name"
  default     = "sandbox"
}

variable "databricks_group_prefix" {
  type        = string
  description = "Databricks Accounts and Workspace Group Name Prefix"
  default     = "example-group"
}

variable "tags" {
  description = "AWS Resource Tag(s)"
  default     = {}
}
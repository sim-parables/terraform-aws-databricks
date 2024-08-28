## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "aws_kms_key_arn" {
  type        = string
  description = "AWS Bucket Name for Databricks Accounts. Required for Buckets with Custom KMS Encryption Keys"
}

variable "databricks_bucket_arns" {
    type        = list(string)
    description = "List of S3 Bucket ARNs to allow access from Databricks"
}

variable "databricks_unity_catalog_role_name" {
  type        = string
  description = "Databricks Workspace Unity Catalog Role Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_storage_credential_iam_arn" {
    type        = string
    description = "Databrick Workspace Storage Credential IAM ARN"
    default     = null
}

variable "databricks_storage_credential_external_id" {
    type        = string
    description = "Databrick Workspace Storage Credential External ID"
    default     = "0000"
}

variable "tags" {
  description = "AWS Resource Tag(s)"
  default     = {}
}
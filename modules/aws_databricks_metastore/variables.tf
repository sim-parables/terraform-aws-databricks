## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "aws_s3_bucket_name" {
  type        = string
  description = "AWS S3 Bucket Name for Databricks MWS and Unity Catalog"
}

variable "aws_s3_bucket_arn" {
  type        = string
  description = "AWS S3 Bucket ARN for Databricks MWS and Unity Catalog"
}

variable "databricks_storage_name" {
  type        = string
  description = "Databricks Workspace Storage Name"
}

variable "databricks_admin_group" {
  type        = string
  description = "Databricks Unity Catalog Administrator Group"
}

variable "databricks_workspace_number" {
  type        = number
  description = "Databricks Workspace ID (Number Only)"
}

variable "databricks_metastore_grants" {
  description = "List of Databricks Metastore Grant Mappings"
  type        = list(object({
    principal = string
    privileges = list(string)
  }))
}

variable "databricks_catalog_grants" {
  description = "List of Databricks Unity Catalog Grant Mappings"
  type        = list(object({
    principal = string
    privileges = list(string)
  }))
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_catalog_name" {
  type        = string
  description = "Databricks Catalog Name"
  default     = "sandbox"
}

variable "tags" {
  description = "AWS Resource Tag(s)"
  default     = {}
}
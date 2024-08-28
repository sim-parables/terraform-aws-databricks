## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "DATABRICKS_ACCOUNT_ID" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "aws_s3_bucket_name" {
  type        = string
  description = "AWS S3 Bucket Name for Databricks Workspace and Unity Catalog"
  default     = "databricks-uc-bucket"
}

variable "aws_kms_key_name" {
  type        = string
  description = "AWS Key Management Service Encryption Key Name"
  default     = "databricks-kms-key"
}

variable "aws_databricks_iam_role_name" {
  type        = string
  description = "AWS IAM Role Name for Databricks Workspace Assume Role"
  default     = "databricks-workspace-assume-role"
}

variable "aws_databricks_vpc_name" {
  type        = string
  description = "AWS VPC Name for Databricks Workspace"
  default     = "databricks-workspace-vpc"
}

variable "databricks_workspace_name" {
  type        = string
  description = "Databricks Workspace Name"
  default     = "databricks-workspace"
}

variable "databricks_token_comment" {
  type        = string
  description = "Databricks Token Generation Comment/Description"
  default     = "terraform-aws-databricks Automated TF Token"
}

variable "tags" {
  description = "AWS Resource Tag(s)"
  default     = {}
}
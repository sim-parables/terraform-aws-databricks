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

variable "aws_databricks_client_id_secret_name" {
  type        = string
  description = "AWS IAM Client ID KMS and Databricks Secret Name for Databricks Service Principal"
  default     = "databricks-sp-client-id"
}

variable "aws_databricks_client_secret_secret_name" {
  type        = string
  description = "AWS IAM Client Secret KMS and Databricks Secret Name for Databricks Service Principal"
  default     = "databricks-sp-client-secret"
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

variable "databricks_group_prefix" {
  type        = string
  description = "Databricks Accounts and Workspace Group Name Prefix"
  default     = "example-group"
}

variable "databricks_token_comment" {
  type        = string
  description = "Databricks Token Generation Comment/Description"
  default     = "terraform-aws-databricks Automated TF Token"
}

variable "databricks_catalog_name" {
  type        = string
  description = "Display Name for Databricks Accounts Metastore Catalog"
  default     = "example_metastore"
}

variable "databricks_catalog_grants" {
  description = <<EOT
    List of Databricks Catalog Specific Grants. Default privileges when creating a metastore
    should include: CREATE_SCHEMA, CREATE_FUNCTION, CREATE_TABLE, CREATE_VOLUME, 
        USE_CATALOG, USE_SCHEMA, READ_VOLUME, SELECT
  EOT
  default     = []
  type        = list(string)
}

variable "databricks_metastore_grants" {
  description = <<EOT
    List of Databricks Metastore Specific Grants. Default privileges when creating a metastore
    should include: CREATE_CATALOG, CREATE_CONNECTION, CREATE_EXTERNAL_LOCATION, CREATE_STORAGE_CREDENTIAL
  EOT
  default     = []
  type        = list(string)
}

variable "databricks_secret_scope_name" {
  type        = string
  description = "Databricks Workspace Secret Scope Name"
  default     = "example-secret"
}

variable "tags" {
  description = "AWS Resource Tag(s)"
  default     = {}
}
## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "aws_kms_key_id" {
  type        = string
  description = "AWS Key Management Service Encryption Key ID"
}

variable "aws_service_principal_name" {
  type        = string
  description = "AWS Service Prinicpal Name which is Authorized for Databricks"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

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

variable "databricks_secret_scope_name" {
  type        = string
  description = "Databricks Workspace Secret Scope Name"
  default     = "example-secret"
}
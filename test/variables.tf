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

variable "service_account_name" {
  type        = string
  description = "New AWS Service Account to be Created"
}

variable "service_account_path" {
  type        = string
  description = "New AWS Service Account Path"
}

variable "OIDC_PROVIDER_ARN" {
  type        = string
  description = "Existing AWS IAM OpenID Connect Provider ARN"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "GITHUB_REPOSITORY_OWNER" {
  type        = string
  description = "Github Actions Default ENV Variable for the Repo Owner"
  default     = "sim-parables"
}

variable "GITHUB_REPOSITORY" {
  type        = string
  description = "Github Actions Default ENV Variable for the Repo Path"
  default     = "sim-parables/terraform-aws-service-account"
}

variable "GITHUB_REF" {
  type        = string
  description = "Github Actions Default ENV Variable for full form of the Branch or Tag"
  default     = null
}

variable "GITHUB_ENV" {
  type        = string
  description = <<EOT
    Github Environment in which the Action Workflow's Job or Step is running. Ex: production.
    This is not found in Github Action's Default Environment Variables and will need to be
    defined manually.
  EOT
  default     = null
}

variable "DATABRICKS_CLI_PROFILE" {
  type        = string
  description = "Databricks CLI configuration Profile name for Databricks Accounts Authentication"
  default     = "AWS_ACCOUNTS"
}

variable "DATABRICKS_CLUSTERS" {
  type        = number
  description = "Number representing the amount of Databricks Clusters to spin up"
  default     = 0
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

variable "tags" {
  description = "AWS Resource Tag(s)"
  default     = {}
}
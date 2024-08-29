terraform {
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.workspace]
    }
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.auth_session]
    }
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM USER DATA SOURCE
##
## This data souce contains Service Account attributes for downstream configuration.
##
## Parameters:
## - `user_name`: The IAM user for whom the access key needs creation.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_user" "this" {
  provider  = aws.auth_session
  user_name = var.aws_service_principal_name
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM ACCESS KEY RESOURCE
##
## This resource creates an access key for the dowstream infra deployment.
##
## Parameters:
## - `user`: The IAM user for whom the access key is created.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_access_key" "this" {
  provider = aws.auth_session
  user     = data.aws_iam_user.this.user_name
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS SECRET CLIENT ID MODULE
##
## Deploys an AWS Secret Manager secret for the Databricks Service Principal Client ID.
##
## Parameters:
## - `kms_key_id`: The ID of the AWS KMS key used to encrypt the secret.
## - `secret_name`: The name of the secret.
## - `secret_description`: The description of the secret.
## - `secret_value`: The value of the secret (in this case, the AWS access key).
## - `administrator_arn`: The ARN of the AWS IAM administrator.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_secret_client_id" {
  source = "../aws_secret"

  kms_key_id         = var.aws_kms_key_id
  secret_name        = var.aws_databricks_client_id_secret_name
  secret_description = "Databricks Service Principal Client ID to Read Blobs"
  secret_value       = data.aws_iam_user.this.user_id
  administrator_arn  = data.aws_iam_user.this.arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS SECRET CLIENT SECRET MODULE
##
## Deploys an AWS Secret Manager secret for the Databricks Service Principal Client Secret.
##
## Parameters:
## - `kms_key_id`: The ID of the AWS KMS key used to encrypt the secret.
## - `secret_name`: The name of the secret.
## - `secret_description`: The description of the secret.
## - `secret_value`: The value of the secret (in this case, the AWS access key).
## - `administrator_arn`: The ARN of the AWS IAM administrator.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_secret_client_secret" {
  source = "../aws_secret"

  kms_key_id         = var.aws_kms_key_id
  secret_name        = var.aws_databricks_client_secret_secret_name
  secret_description = "Databricks Service Principal Client Secret to Read Blobs"
  secret_value       = aws_iam_access_key.this.secret
  administrator_arn  = data.aws_iam_user.this.arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SECRET SCOPE MODULE
## 
## This module creates a Databricks secret scope in an Azure Databricks workspace. We're unable to create a
## Databricks Secret Scope backed by Azure Key Vault due to the workspace provider requiring Azure specific
## authentication methods (Cannot be created using PAT).
## 
## Parameters:
## - `secret_scope`: Specifies the name of Databricks Secret Scope.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_secret_scope" {
  source = "github.com/sim-parables/terraform-databricks//modules/databricks_secret_scope?ref=fe03c8ba5c8b65b4b51ef6e7eb3af56f8952ead5"

  secret_scope = var.databricks_secret_scope_name

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE ACCOUNT KEY NAME SECRET MODULE
## 
## This module creates a secret in a Databricks secret scope. The secret stores the client ID 
## of an Azure service principal
## 
## Parameters:
## - `secret_scope_id`: Specifies the secret scope ID where the secret will be stored
## - `secret_name`: Specifies the name of the secret
## - `secret_data`: Specifies the data of the secret (client ID of the Azure service principal)
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_service_account_key_name_secret" {
  source     = "github.com/sim-parables/terraform-databricks//modules/databricks_secret?ref=fe03c8ba5c8b65b4b51ef6e7eb3af56f8952ead5"
  depends_on = [module.databricks_secret_scope]

  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = var.aws_databricks_client_id_secret_name
  secret_data     = data.aws_iam_user.this.user_id

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE ACCOUNT KEY SECRET MODULE
## 
## This module creates a secret in a Databricks secret scope. The secret stores the client Secret 
## of an Azure service principal
## 
## Parameters:
## - `secret_scope_id`: Specifies the secret scope ID where the secret will be stored
## - `secret_name`: Specifies the name of the secret
## - `secret_data`: Specifies the data of the secret (client Secret of the Azure service principal)
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_service_account_key_data_secret" {
  source     = "github.com/sim-parables/terraform-databricks//modules/databricks_secret?ref=fe03c8ba5c8b65b4b51ef6e7eb3af56f8952ead5"
  depends_on = [module.databricks_secret_scope]

  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = var.aws_databricks_client_secret_secret_name
  secret_data     = aws_iam_access_key.this.secret

  providers = {
    databricks.workspace = databricks.workspace
  }
}

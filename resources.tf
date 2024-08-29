terraform {
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.accounts]
    }
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.auth_session]
    }
  }
}

data "aws_region" "current" {
  provider = aws.auth_session
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS CALLER IDENTITY DATA
##
## Retrieves the AWS caller identity using the configured authentication session.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {
  provider = aws.auth_session
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS KMS KEY MODULE
##
## Deploys an AWS Key Management Service (KMS) key.
##
## Parameters:
## - `kms_key_name`: The name of the KMS key.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_kms_key" {
  source       = "./modules/aws_kms_key"
  kms_key_name = var.aws_kms_key_name

  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS STORAGE CONFIGURATION MODULE
##
## This resource creates and S3 Bucket and configures a storage configuration for Databricks MultiWorkspace Services.
##
## Parameters:
## - `databricks_account_id`: The Databricks account ID.
## - `aws_bucket_name`: The name of the AWS S3 bucket.
## - `aws_kms_key_arn`: KMS encryption key ARN.
## - `storage_configuration_name`: The name of the storage configuration.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_storage_configuration" {
  source = "./modules/databricks_storage_configuration"

  databricks_account_id                 = var.DATABRICKS_ACCOUNT_ID
  aws_bucket_name                       = var.aws_s3_bucket_name
  aws_kms_key_arn                       = module.aws_kms_key.kms_key_arn
  databricks_storage_configuration_name = "${var.aws_s3_bucket_name}-storage-config"

  providers = {
    databricks.accounts = databricks.accounts
    aws.auth_session    = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS IAM ROLE MODULE
##
## This module creates an IAM role for Databricks workspace.
##
## Parameters:
## - `databricks_account_id`: The ID of the Databricks account.
## - `aws_iam_role_name`: The name of the AWS IAM role.
## - `tags`: Tags to apply to the IAM role.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_iam_role" {
  source                = "./modules/aws_databricks_iam_role"
  databricks_account_id = var.DATABRICKS_ACCOUNT_ID
  aws_iam_role_name     = var.aws_databricks_iam_role_name
  tags                  = var.tags

  providers = {
    aws.auth_session    = aws.auth_session
    databricks.accounts = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS VPC MODULE
##
## This module creates a VPC for Databricks workspace.
##
## Parameters:
## - `databricks_account_id`: The ID of the Databricks account.
## - `aws_vpc_name`: The name of the AWS VPC.
## - `tags`: Tags to apply to the VPC.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_vpc" {
  source                = "./modules/databricks_vpc"
  databricks_account_id = var.DATABRICKS_ACCOUNT_ID
  aws_vpc_name          = var.aws_databricks_vpc_name
  tags                  = var.tags

  providers = {
    aws.auth_session    = aws.auth_session
    databricks.accounts = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MWS WORKSPACES RESOURCE
##
## This resource creates a Databricks MultiWorkspace Services (MWS) workspace.
##
## Parameters:
## - `account_id`: The ID of the Databricks account.
## - `aws_region`: The AWS region.
## - `workspace_name`: The name of the workspace.
## - `credentials_id`: The ID of the IAM role for credentials.
## - `storage_configuration_id`: The ID of the storage configuration.
## - `network_id`: The ID of the network.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_workspaces" "this" {
  provider = databricks.accounts
  depends_on = [
    module.databricks_storage_configuration,
    module.databricks_iam_role,
    module.databricks_vpc
  ]

  account_id               = var.DATABRICKS_ACCOUNT_ID
  aws_region               = data.aws_region.current.name
  workspace_name           = var.databricks_workspace_name
  credentials_id           = module.databricks_iam_role.credentials_id
  storage_configuration_id = module.databricks_storage_configuration.storage_configuration_id
  network_id               = module.databricks_vpc.network_id

  token {
    comment = var.databricks_token_comment
  }
}



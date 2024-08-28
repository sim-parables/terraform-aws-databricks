terraform{
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.accounts, ]
    }
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.auth_session, ]
    }
  }
}


##---------------------------------------------------------------------------------------------------------------------
## DATABRICKS BUCKET MODULE
##
## This module creates an S3 bucket for Databricks Workspace Storage Configuration.
##
## Parameters:
## - `bucket_name`: S3 name.
## - `kms_key_arn`: AWS KMS Encryption Key ARN.
##---------------------------------------------------------------------------------------------------------------------
module "databricks_bucket" {
  source = "github.com/sim-parables/terraform-aws-blob-trigger//modules/s3_bucket?ref=f79892d5eac2ad93d5ada1aa7f2a83822b6cc2de"

  bucket_name = var.aws_bucket_name
  kms_key_arn = var.aws_kms_key_arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}


##---------------------------------------------------------------------------------------------------------------------
## DATABRICKS AWS BUCKET POLICY DATA SOURCE
##
## This Data Source creates a preconfigured AWS IAM Policy with Databricks Account's root AWS Account ID and access
## to grant access, read/write permissions and allow Databricks Workplace creation to complete succesfully.
##
## Parameters:
## - `bucket`: S3 name.
##---------------------------------------------------------------------------------------------------------------------
data "databricks_aws_bucket_policy" "this" {
  provider         = databricks.accounts

  bucket           = module.databricks_bucket.bucket_id
}

##---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET POLICY RESOURCE
##
## Assign the Databricks AWS Bucket Policy to the S3 bucket to allow Databricks access for Storage Configuration.
##
## Parameters:
## - `bucket`: S3 name.
## - `policy`: The Databricks AWS policy in JSON structure.
##---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "this" {
  provider   = aws.auth_session
  depends_on = [ module.databricks_bucket ]

  bucket = module.databricks_bucket.bucket_id
  policy = data.databricks_aws_bucket_policy.this.json
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MULTIWORKSPACE SERVICES STORAGE CONFIGURATION RESOURCE
##
## This resource configures a storage configuration for Databricks MultiWorkspace Services.
##
## Parameters:
## - `account_id`: The Databricks account ID.
## - `bucket_name`: The name of the AWS S3 bucket.
## - `storage_configuration_name`: The name of the storage configuration.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_storage_configurations" "this" {
  provider   = databricks.accounts
  depends_on = [ aws_s3_bucket_policy.this ]

  account_id                 = var.databricks_account_id
  bucket_name                = module.databricks_bucket.bucket_id
  storage_configuration_name = var.databricks_storage_configuration_name
}
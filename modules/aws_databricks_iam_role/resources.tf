/* Databricks AWS IAM Role Configurations & Service Account Creation */

terraform {
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.accounts, ]
    }
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.auth_session, ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS AWS ASSUME ROLE POLICY DATA SOURCE
##
## This data source retrieves the assume role policy for AWS.
##
## Parameters:
## - `external_id`: The external ID for the Databricks account.
##
## Providers:
## - `databricks.accounts`: The Databricks provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_aws_assume_role_policy" "this" {
  provider    = databricks.accounts
  external_id = var.databricks_account_id
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS AWS CROSSACCOUNT POLICY DATA SOURCE
##
## This data source retrieves the cross-account policy for AWS.
##
## Providers:
## - `databricks.accounts`: The Databricks provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_aws_crossaccount_policy" "this" {}

## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM ROLE RESOURCE
##
## An IAM role is an AWS identity with permission policies that determine what the identity can and cannot do in AWS.
##
## Parameters:
## - `name`: The name of the IAM role.
## - `assume_role_policy`: The policy that grants an entity permission to assume the role.
## - `tags`: A mapping of tags to assign to the IAM role.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "this" {
  provider           = aws.auth_session
  name               = var.aws_iam_role_name
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
  tags               = var.tags
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM ROLE POLICY RESOURCE
##
## An IAM role policy is an entity-specific policy that can be attached to an IAM role, defining permissions for the role.
##
## Parameters:
## - `name`: The name of the IAM role policy.
## - `role`: The IAM role to which the policy is attached.
## - `policy`: The JSON policy document defining the permissions for the role.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "this" {
  provider = aws.auth_session
  name     = "${var.aws_iam_role_name}-policy"
  role     = aws_iam_role.this.id
  policy   = data.databricks_aws_crossaccount_policy.this.json
}


## ---------------------------------------------------------------------------------------------------------------------
## TIME_SLEEP RESOURCE
##
## This resource adds a delay to wait for the workspace to enable identity federation.
##
## Parameters:
## - `create_duration`: The duration to wait before completing module databricks_mws_credential.
##
## Dependencies:
## - `aws_iam_role_policy.this`: The AWS IAM Role Policy resource.
## ---------------------------------------------------------------------------------------------------------------------
resource "time_sleep" "this" {
  depends_on = [
    aws_iam_role_policy.this
  ]
  create_duration = "20s"
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MWS CREDENTIALS RESOURCE
##
## Databricks MWS Credentials allow authentication to Databricks using an AWS IAM Role.
##
## Parameters:
## - `account_id`: The Databricks account ID.
## - `role_arn`: The ARN of the IAM role used for authentication.
## - `credentials_name`: The name of the Databricks credentials.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_credentials" "this" {
  provider = databricks.accounts
  depends_on = [
    aws_iam_role_policy.this,
    time_sleep.this
  ]

  account_id       = var.databricks_account_id
  role_arn         = aws_iam_role.this.arn
  credentials_name = "${var.aws_iam_role_name}-credentials"
}

terraform{
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.auth_session, ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS CALLER IDENTITY DATA SOURCE
##
## This data source retrieves the AWS account ID and ARN for the caller making the request.
##
## Providers:
## - `aws.auth_session`: The AWS provider with authentication session.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {
  provider = aws.auth_session
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM POLICY DOCUMENT DATA SOURCE
##
## This data source generates an IAM policy document that allows specified AWS principals to read secrets from Secrets Manager.
##
## Providers:
## - `aws.auth_session`: The AWS provider with authentication session.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "this" {
  provider = aws.auth_session
  
  statement {
    sid    = "EnableAnotherAWSAccountToReadTheSecret"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [
        data.aws_caller_identity.current.arn,
        var.administrator_arn
      ]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string of a specified length.
##
## Parameters:
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `length`: The length of the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}


locals {
  cloud   = "aws"
  program = "spark-databricks"
  project = "datasim"
}

locals  {
  prefix      = "${local.program}-${local.project}-${random_string.this.id}"
  description = var.secret_description != null ? var.secret_description : "${local.prefix} ${var.secret_name} Secret by Terraform"
  tags    = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS SECRETS MANAGER SECRET RESOURCE
##
## This resource creates a secret in AWS Secrets Manager.
##
## Parameters:
## - `kms_key_id`: The ID of the AWS KMS key.
## - `name`: The name of the secret.
## - `description`: The description of the secret.
## - `recovery_window_in_days`: The number of days that AWS Secrets Manager retains a past version of the secret before it deletes it.
## - `tags`: The tags to assign to the secret.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "this" {
  provider                = aws.auth_session
  kms_key_id              = var.kms_key_id
  name                    = var.secret_name
  description             = local.description
  recovery_window_in_days = var.recovery_window_in_days
  tags                    = local.tags
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS SECRETS MANAGER SECRET POLICY RESOURCE
##
## This resource attaches a policy to an AWS Secrets Manager secret.
##
## Parameters:
## - `secret_arn`: The ARN of the secret to attach the policy.
## - `policy`: The JSON policy document defining the permissions for the secret.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_secretsmanager_secret_policy" "this" {
  provider   = aws.auth_session
  secret_arn = aws_secretsmanager_secret.this.arn
  policy     = data.aws_iam_policy_document.this.json
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS SECRETS MANAGER SECRET VERSION RESOURCE
##
## This resource creates a new version of the secret with the specified secret string.
##
## Parameters:
## - `secret_id`: The ID of the secret for which to create the new version.
## - `secret_string`: The plaintext secret value to store in the new version.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "this" {
  provider      = aws.auth_session
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_value
}

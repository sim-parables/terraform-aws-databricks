terraform{
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.auth_session, ]
    }
  }
}


# More details on this static IAM role can be found here
# https://docs.databricks.com/en/connect/unity-catalog/storage-credentials.html
locals {
  databricks_aws_arn = [
    "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL",
    var.databricks_storage_credential_iam_arn == null ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root": var.databricks_storage_credential_iam_arn,
  ]

  aws_bucket_arns = flatten([
    for arn in var.databricks_bucket_arns : [
        arn,
        "${arn}/*"
    ]
  ])
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS CALLER IDENTITY DATA BLOCK
##
## This data block retrieves the caller identity information for the current AWS session.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {
    provider = aws.auth_session
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM POLICY DOCUMENT DATA BLOCK
##
## This data block defines an IAM policy document allowing the specified role assumption.
##
## Parameters:
## - `var.unity_catalog_iam_arn`: The ARN of the IAM role for the Unity catalog.
## - `var.databricks_storage_credential_iam_external_id`: External ID for Databricks storage credential IAM.
## - `role_name`: Local variable representing the IAM role name.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "this" {
    provider = aws.auth_session

    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            identifiers = local.databricks_aws_arn
            type        = "AWS"
        }
        condition {
            test     = "StringEquals"
            variable = "sts:ExternalId"
            values   = [var.databricks_storage_credential_external_id]
        }
    }

    statement {
        sid     = "ExplicitSelfRoleAssumption"
        effect  = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type        = "AWS"
            identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
        condition {
            test     = "ArnLike"
            variable = "aws:PrincipalArn"
            values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.databricks_unity_catalog_role_name}-role"]
        }
    }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM POLICY RESOURCE BLOCK
##
## This resource block defines an IAM policy allowing specified actions on the Databricks Metastore bucket and role assumption.
##
## Parameters:
## - `local.role_name`: Local variable representing the IAM role name.
## - `var.databricks_metastore_bucket_arn`: ARN of the Databricks Metastore bucket.
## - `data.aws_caller_identity.current.account_id`: AWS account ID.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "this" {
    provider = aws.auth_session
    name     = "${var.databricks_unity_catalog_role_name}-policy"
    policy   = jsonencode({
        Version   = "2012-10-17"
        Id        = "${var.databricks_unity_catalog_role_name}-policy-definition"
        Statement = [
            {
                Action   = [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket",
                    "s3:GetBucketLocation",
                    "kms:*",
                ]
                Resource = local.aws_bucket_arns
                Effect   = "Allow"
            },
            {
                Action = [
                    "kms:Decrypt",
                    "kms:Encrypt",
                    "kms:GenerateDataKey*"
                ],
                Resource = [
                    var.aws_kms_key_arn
                ],
                Effect = "Allow"
            },
            {
                Action   = [
                    "sts:AssumeRole"
                ]
                Resource = [
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
                ]
                Effect   = "Allow"
            }
        ]
    })
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM ROLE RESOURCE
##
## This resource defines an IAM role in AWS.
##
## Parameters:
## - `name`: The name of the IAM role.
## - `assume_role_policy`: The JSON policy document that grants an entity permission to assume the role.
## - `managed_policy_arns`: A list of ARNs of managed policies to attach to the role.
## - `tags`: A map of tags to assign to the IAM role.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "this" {
    provider            = aws.auth_session
    name                = "${var.databricks_unity_catalog_role_name}-role"
    assume_role_policy  = data.aws_iam_policy_document.this.json
    managed_policy_arns = [aws_iam_policy.this.arn]
    tags                = var.tags

    lifecycle {
      ignore_changes = [ 
        assume_role_policy,
        managed_policy_arns 
      ]
    }
}

terraform{
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.auth_session, ]
    }
  }
}

locals {
  cloud   = "aws"
  program = "spark-databricks"
  project = "datasim"
}

locals  {
  tags    = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS KMS KEY RESOURCE
##
## This resource creates an AWS Key Management Service (KMS) key.
##
## Parameters:
## - `description`: The description of the KMS key.
## - `deletion_window_in_days`: The number of days in the key deletion window.
## - `tags`: The tags to assign to the KMS key.
##
## Providers:
## - `aws.auth_session`: The AWS provider with authentication session.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "this" {
  provider                = aws.auth_session

  description             = var.kms_key_name
  deletion_window_in_days = var.kms_retention_days
  tags                    = local.tags
}

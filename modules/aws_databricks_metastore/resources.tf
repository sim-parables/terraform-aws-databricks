terraform{
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [
         databricks.accounts, 
         databricks.workspace
      ]
    }
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.auth_session, ]
    }
  }
}

data "aws_region" "current" {
    provider = aws.auth_session
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE MODULE
##
## This module creates Databricks metastores and assigns them to Databricks Workspaces for Unity Catalog.
##
## Parameters:
## - `databricks_metastore_name`: The name of the Databricks metastore.
## - `databricks_unity_admin_group`: The name of the owner group for the Databricks metastore.
## - `databricks_storage_root`: The root URL of the external storage associated with the metastore.
## - `cloud_region`: The region where the Databricks metastore is located.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_metastore" {
  source   = "github.com/sim-parables/terraform-databricks//modules/databricks_metastore?ref=c05bc4f94a1167c550496f2f3565fa319f68bf8b"

  databricks_metastore_name    = var.databricks_storage_name
  databricks_unity_admin_group = var.databricks_admin_group
  databricks_workspace_id      = var.databricks_workspace_number
  databricks_storage_root      = "s3://${var.aws_s3_bucket_name}"
  databricks_metastore_grants  = var.databricks_metastore_grants
  cloud_region                 = data.aws_region.current.name

  providers = {
    databricks.accounts = databricks.accounts
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS UNITY CATALOG CROSS-ACCOUNT POLICY STEP 0 MODULE
##
## This module configures cross-account policies for AWS Unity Catalog. Role creation is a two-step process. In this 
## step you create the role, adding a temporary trust relationship policy and a placeholder external ID that you then 
## modify after creating the storage credential in Databricks.
##
## Parameters:
## - `databricks_unity_catalog_role_name`: The name of the Databricks Unity Catalog role.
## - `databricks_metastore_bucket_arn`: The ARN of the Databricks metastore bucket.
## - `tags`: Tags to be applied to AWS resources.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_unity_catalog_crossaccount_policy_step_0" {
  source = "./modules/aws_unity_catalog_crossaccount_policy"
  
  databricks_unity_catalog_role_name        = var.databricks_storage_name
  databricks_metastore_bucket_arn           = var.aws_s3_bucket_arn
  tags                                      = var.tags
  
  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS STORAGE CREDENTIAL RESOURCE
##
## This resource defines a storage credential in Databricks.
##
## Parameters:
## - `name`: The name of the storage credential.
## - `aws_iam_role`: The IAM role ARN used by Databricks to access AWS services.
##
## Providers:
## - `databricks.workspace`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_storage_credential" "this" {
  provider = databricks.workspace
  
  name     = "${var.databricks_storage_name}-credential"
  aws_iam_role {
    role_arn = module.aws_unity_catalog_crossaccount_policy_step_0.databricks_metastore_cross_account_policy_arn
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS UNITY CATALOG CROSS-ACCOUNT POLICY STEP 1 MODULE
##
## This module updates the cross-account policies for AWS Unity Catalog. Modify the trust relationship policy to add 
## your storage credential’s external ID and make it self-assuming.
##
## Parameters:
## - `databricks_unity_catalog_role_name`: The name of the Databricks Unity Catalog role.
## - `databricks_metastore_bucket_arn`: The ARN of the Databricks metastore bucket.
## - `databricks_storage_credential_external_id`: The external ID of the Databricks storage credential IAM role.
## - `databricks_storage_credential_iam_arn`: The ARN of the Unity Catalog IAM role.
## - `tags`: Tags to be applied to AWS resources.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_unity_catalog_crossaccount_policy_step_1" {
  source = "./modules/aws_unity_catalog_crossaccount_policy"
  
  databricks_unity_catalog_role_name        = var.databricks_storage_name
  databricks_metastore_bucket_arn           = var.aws_s3_bucket_arn
  databricks_storage_credential_external_id = databricks_storage_credential.this.aws_iam_role[0].external_id
  databricks_storage_credential_iam_arn     = databricks_storage_credential.this.aws_iam_role[0].role_arn
  tags                                      = var.tags
  
  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## TIME SLEEP RESOURCE
##
## This resource defines a delay to allow time for Databricks Metastore grants to propagate.
##
## Parameters:
## - `create_duration`: The duration for the time sleep.
## ---------------------------------------------------------------------------------------------------------------------
resource "time_sleep" "grant_propogation" {
  depends_on = [ 
    module.databricks_metastore,
    databricks_storage_credential.this
  ]

  create_duration = "30s"
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS EXTERNAL LOCATION MODULE
##
## This resource defines an external location in Databricks and applies the location & metastore to catalog.
##
## Parameters:
## - `databricks_external_location_name`: The name of the external location.
## - `databricks_external_storage_url`: The URL of the external location.
## - `databricks_storage_credential_name`: The ID of the storage credential associated with this external location.
## - `databricks_catalog_grants`: List of Databricks Catalog roles mappings to grant to specific principal.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_external_location" {
  source     = "github.com/sim-parables/terraform-databricks//modules/databricks_external_location?ref=c05bc4f94a1167c550496f2f3565fa319f68bf8b"
  depends_on = [
    databricks_storage_credential.this,
    module.databricks_metastore,
    time_sleep.grant_propogation
  ]

  databricks_external_location_name = var.databricks_storage_name
  databricks_external_storage_url   = "s3://${var.aws_s3_bucket_name}"
  databricks_storage_credential_id  = databricks_storage_credential.this.id
  databricks_catalog_grants         = var.databricks_catalog_grants
  databricks_catalog_name           = var.databricks_catalog_name

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE DATA ACCESS RESOURCE
##
## This resource configures data access for Databricks Metastore.
##
## Parameters:
## - `metastore_id`: The ID of the Databricks Metastore.
## - `name`: The name of the data access policy.
## - `aws_iam_role`: Configuration for the AWS IAM role.
## - `is_default`: Specifies if this is the default data access policy.
##
## Providers:
## - `databricks.workspace`: The Databricks provider for workspace.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_metastore_data_access" "this" {
  provider     = databricks.workspace

  metastore_id = module.databricks_metastore.metastore_id
  name         = module.aws_unity_catalog_crossaccount_policy_step_1.databricks_metastore_data_access_policy_name
  is_default   = true
  
  aws_iam_role {
    role_arn = module.aws_unity_catalog_crossaccount_policy_step_1.databricks_metastore_data_access_policy_arn
  }
}
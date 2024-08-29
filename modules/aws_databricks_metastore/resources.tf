terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [
        databricks.accounts,
        databricks.workspace
      ]
    }
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.auth_session, ]
    }
  }
}


locals {
  databricks_metastore_grants = [{
    principal  = "${var.databricks_group_prefix}-admin"
    privileges = var.databricks_metastore_grants
  }]

  databricks_catalog_grants = [{
    principal  = "${var.databricks_group_prefix}-admin"
    privileges = var.databricks_catalog_grants
  }]

  aws_bucket_arns = [
    module.databricks_metastore_bucket.bucket_arn,
    module.databricks_external_bucket.bucket_arn
  ]
}


data "aws_region" "current" {
  provider = aws.auth_session
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE PRINCIPAL RESOURCE
##
## Creates a Databricks workspace level service princiapl. Databricks Accounts Federated Identity will
## propogate the Service Principal to Account level.
##
## Parameters:
## - `display_name`: The service principal name.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_service_principal" "this" {
  provider = databricks.workspace

  display_name = var.databricks_service_principal_name
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE PRINCIPAL ROLE RESOURCE
## 
## Append a Databricks Account role to an existing Databricks service principal.
## 
## Parameters:
## - `service_principal_id`: Databricks Accounts service principal client ID.
## - `role`: Databricks Accounts service principal role name.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_service_principal_role" "this" {
  provider = databricks.accounts

  service_principal_id = databricks_service_principal.this.id
  role                 = "account_admin"
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE PRINCIPAL ROLE RESOURCE
## 
## Append a Databricks Account role to an existing Databricks service principal.
## 
## Parameters:
## - `service_principal_id`: Databricks Accounts service principal client ID.
## - `role`: Databricks Accounts service principal role name.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_user" "this" {
  provider   = databricks.accounts
  depends_on = [databricks_service_principal_role.this]

  user_name = var.DATABRICKS_ADMINISTRATOR
}


data "databricks_current_user" "this" {
  provider = databricks.workspace
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS ADMIN GROUP MODULE
##
## This module creates a Databricks group with administrative privileges, and assigns both the Databricks Accounts
## admin & the Azure Service Principal to the admin group.
##
## Parameters:
## - `group_name`: The name of the Databricks group.
## - `allow_cluster_create`: Whether to allow creating clusters.
## - `allow_databricks_sql_access`: Whether to allow access to Databricks SQL.
## - `allow_instance_pool_create`: Whether to allow creating instance pools.
## - `member_ids`: List of Databricks member IDs to assign into the group.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_admin_group" {
  source     = "github.com/sim-parables/terraform-databricks//modules/databricks_group?ref=fe03c8ba5c8b65b4b51ef6e7eb3af56f8952ead5"
  depends_on = [databricks_service_principal_role.this]

  group_name                  = "${var.databricks_group_prefix}-admin"
  allow_cluster_create        = true
  allow_databricks_sql_access = true
  allow_instance_pool_create  = true
  member_ids = [
    data.databricks_user.this.id,
    databricks_service_principal.this.id,
    data.databricks_current_user.this.id
  ]

  providers = {
    databricks.workspace = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS USER GROUP MODULE
##
## This module creates a Databricks group with user privileges.
##
## Parameters:
## - `group_name`: The name of the Databricks group.
## - `allow_databricks_sql_access`: Whether to allow access to Databricks SQL.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_user_group" {
  source     = "github.com/sim-parables/terraform-databricks//modules/databricks_group?ref=fe03c8ba5c8b65b4b51ef6e7eb3af56f8952ead5"
  depends_on = [databricks_service_principal_role.this]

  group_name                  = "${var.databricks_group_prefix}-user"
  allow_databricks_sql_access = true

  providers = {
    databricks.workspace = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS PERMISSION RESOURCE
##
## Create a permission at the Databricks Workspace level to allow token generation through Terraform.
##
## Parameters:
## - `authorization`: Type of permission.
## - `service_principal_name`: The Databricks Workspace service principal application ID.
## - `permission_leve`: Allow or deny permission on service principal.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_permissions" "this" {
  provider = databricks.workspace
  depends_on = [
    module.databricks_admin_group,
    module.databricks_user_group
  ]

  authorization = "tokens"
  access_control {
    service_principal_name = databricks_service_principal.this.application_id
    permission_level       = "CAN_USE"
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE PRINCIPAL ROLE RESOURCE
## 
## Append a Databricks Account role to an existing Databricks service principal.
## 
## Parameters:
## - `application_id`: Databricks service principal client ID.
## - `comment`: Databricks Personal Access Token Comment.
## - `lifetime_seconds`: Databricks token lifetime in seconds.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_obo_token" "this" {
  provider   = databricks.workspace
  depends_on = [databricks_permissions.this]

  application_id   = databricks_service_principal.this.application_id
  comment          = "PAT on behalf of ${databricks_service_principal.this.display_name}"
  lifetime_seconds = var.databricks_service_principal_token_seconds
}


##---------------------------------------------------------------------------------------------------------------------
## DATABRICKS BUCKET MODULE
##
## This module creates an S3 bucket for Databricks Workspace & Unity Catalog. The metastore bucket and external storage
## bucket require seperate cloud storage locations otherwise Databricks workspace level configurations fail due to
## overlapping root storage locations.
##
## Parameters:
## - `bucket_name`: S3 name.
## - `kms_key_arn`: AWS KMS Encryption Key ARN.
##---------------------------------------------------------------------------------------------------------------------
module "databricks_metastore_bucket" {
  source = "github.com/sim-parables/terraform-aws-blob-trigger//modules/s3_bucket?ref=f79892d5eac2ad93d5ada1aa7f2a83822b6cc2de"

  bucket_name = var.databricks_storage_name
  kms_key_arn = var.aws_kms_key_arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}


##---------------------------------------------------------------------------------------------------------------------
## DATABRICKS BUCKET MODULE
##
## This module creates an S3 bucket for Databricks Workspace & Unity Catalog. The metastore bucket and external storage
## bucket require seperate cloud storage locations otherwise Databricks workspace level configurations fail due to
## overlapping root storage locations.
##
## Parameters:
## - `bucket_name`: S3 name.
## - `kms_key_arn`: AWS KMS Encryption Key ARN.
##---------------------------------------------------------------------------------------------------------------------
module "databricks_external_bucket" {
  source = "github.com/sim-parables/terraform-aws-blob-trigger//modules/s3_bucket?ref=f79892d5eac2ad93d5ada1aa7f2a83822b6cc2de"

  bucket_name = "${var.databricks_storage_name}-external-location"
  kms_key_arn = var.aws_kms_key_arn

  providers = {
    aws.auth_session = aws.auth_session
  }
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
  source = "github.com/sim-parables/terraform-databricks//modules/databricks_metastore?ref=fe03c8ba5c8b65b4b51ef6e7eb3af56f8952ead5"
  depends_on = [
    module.databricks_admin_group,
    module.databricks_metastore_bucket,
    module.databricks_external_bucket
  ]

  databricks_metastore_name    = var.databricks_storage_name
  databricks_unity_admin_group = module.databricks_admin_group.databricks_group_name
  databricks_workspace_id      = var.databricks_workspace_number
  databricks_storage_root      = "s3://${module.databricks_metastore_bucket.bucket_id}"
  databricks_metastore_grants  = local.databricks_metastore_grants
  cloud_region                 = data.aws_region.current.name

  providers = {
    databricks.accounts  = databricks.accounts
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
module "aws_unity_catalog_crossaccount_policy" {
  source     = "./modules/aws_unity_catalog_crossaccount_policy"
  depends_on = [module.databricks_metastore]

  aws_kms_key_arn                           = var.aws_kms_key_arn
  databricks_unity_catalog_role_name        = var.databricks_storage_name
  databricks_bucket_arns                    = local.aws_bucket_arns
  databricks_storage_credential_external_id = var.DATABRICKS_ACCOUNT_ID
  tags                                      = var.tags

  providers = {
    aws.auth_session = aws.auth_session
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
  provider   = databricks.workspace
  depends_on = [module.aws_unity_catalog_crossaccount_policy]

  metastore_id = module.databricks_metastore.metastore_id
  name         = "${var.databricks_catalog_name}-data-access"
  is_default   = true

  aws_iam_role {
    role_arn = module.aws_unity_catalog_crossaccount_policy.databricks_metastore_data_access_policy_arn
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
  provider   = databricks.workspace
  depends_on = [databricks_metastore_data_access.this]

  name = "${var.databricks_storage_name}-credential"
  aws_iam_role {
    role_arn = module.aws_unity_catalog_crossaccount_policy.databricks_metastore_cross_account_policy_arn
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

  create_duration = "300s"
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MWS PERMISSION ASSIGNMENT RESOURCE
##
## This resource assigns the Admin Databricks Account group to the Databricks Workspace level. This allows web portal
## entry and admin level service usability to those members assigned into the group.
##
## Parameters:
## - `workspace_id`: The Databricks Workspace ID.
## - `principal_id`: The Databricks Account level group ID.
## - `permissions`: Specific Databricks Workspace level group permissions (Different to grants).
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_permission_assignment" "admin" {
  provider   = databricks.accounts
  depends_on = [time_sleep.grant_propogation]

  workspace_id = var.databricks_workspace_number
  principal_id = module.databricks_admin_group.databricks_group_id
  permissions  = ["ADMIN"]
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MWS PERMISSION ASSIGNMENT RESOURCE
##
## This resource assigns the User Databricks Account group to the Databricks Workspace level. This allows web portal
## entry and basic level service usability to those members assigned into the group.
##
## Parameters:
## - `workspace_id`: The Databricks Workspace ID.
## - `principal_id`: The Databricks Account level group ID.
## - `permissions`: Specific Databricks Workspace level group permissions (Different to grants).
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_permission_assignment" "user" {
  provider   = databricks.accounts
  depends_on = [time_sleep.grant_propogation]

  workspace_id = var.databricks_workspace_number
  principal_id = module.databricks_user_group.databricks_group_id
  permissions  = ["USER"]
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
  source = "github.com/sim-parables/terraform-databricks//modules/databricks_external_location?ref=fe03c8ba5c8b65b4b51ef6e7eb3af56f8952ead5"
  depends_on = [
    databricks_storage_credential.this,
    time_sleep.grant_propogation
  ]

  databricks_external_location_name = "${var.databricks_storage_name}-external-location"
  databricks_external_storage_url   = "s3://${module.databricks_external_bucket.bucket_id}"
  databricks_storage_credential_id  = databricks_storage_credential.this.id
  databricks_catalog_grants         = local.databricks_catalog_grants
  databricks_catalog_name           = var.databricks_catalog_name

  providers = {
    databricks.workspace = databricks.workspace
  }
}
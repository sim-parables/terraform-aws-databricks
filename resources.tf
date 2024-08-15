terraform{
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.accounts ]
    }
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.auth_session ]
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


locals {
  databricks_metastore_grants = [{
    principal  = "${var.databricks_group_prefix}-admin"
    privileges = var.databricks_metastore_grants
  }]

  databricks_catalog_grants = [{
    principal  = "${var.databricks_group_prefix}-admin"
    privileges = var.databricks_catalog_grants
  }]
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
  user     = data.aws_caller_identity.current.user_id
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
  source           = "./modules/aws_kms_key"
  kms_key_name     = var.aws_kms_key_name

  providers = {
    aws.auth_session = aws.auth_session
  }
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
  source             = "./modules/aws_secret"
  
  kms_key_id         = module.aws_kms_key.kms_key_id
  secret_name        = var.aws_databricks_client_id_secret_name
  secret_description = "Databricks Service Principal Client ID to Read Blobs"
  secret_value       = data.aws_caller_identity.current.user_id
  administrator_arn  = data.aws_caller_identity.current.arn

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
  source             = "./modules/aws_secret"
  
  kms_key_id         = module.aws_kms_key.kms_key_id
  secret_name        = var.aws_databricks_client_secret_secret_name
  secret_description = "Databricks Service Principal Client Secret to Read Blobs"
  secret_value       = aws_iam_access_key.this.secret
  administrator_arn  = data.aws_caller_identity.current.arn

  providers = {
    aws.auth_session = aws.auth_session
  }
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
  depends_on = [ databricks_service_principal_role.this ]
  
  user_name = var.DATABRICKS_ADMINISTRATOR
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
    aws.auth_session = aws.auth_session
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
    aws.auth_session = aws.auth_session
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
  provider       = databricks.accounts
  
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


provider "databricks" {
  alias = "workspace"
  host  = databricks_mws_workspaces.this.workspace_id
  token = databricks_mws_workspaces.this.token[0].token_value
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS CURRENT USER DATA
##
## Retrieves information about the current Service Principal in Databricks. This will be the Databricks
## Accounts admin found in the Databricks CLI Profile.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_current_user" "this" {
  provider   = databricks.workspace
  depends_on = [ databricks_mws_workspaces.this ]
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
  provider   = databricks.accounts
  depends_on = [ databricks_mws_workspaces.this ]
  
  service_principal_id = data.databricks_current_user.this.id
  role                 = "account_admin"
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
  source     = "github.com/sim-parables/terraform-databricks//modules/databricks_group?ref=c05bc4f94a1167c550496f2f3565fa319f68bf8b"
  depends_on = [ databricks_service_principal_role.this ]
  
  group_name                  = "${var.databricks_group_prefix}-admin"
  allow_cluster_create        = true
  allow_databricks_sql_access = true
  allow_instance_pool_create  = true
  member_ids                  = [
    data.databricks_user.this.id,
    data.databricks_current_user.this.id,
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
##
## Providers:
## - `databricks.workspace`: The Databricks provider for managing workspace resources.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_user_group" {
  source     = "github.com/sim-parables/terraform-databricks//modules/databricks_group?ref=c05bc4f94a1167c550496f2f3565fa319f68bf8b"
  depends_on = [ databricks_service_principal_role.this ]
  
  group_name                  = "${var.databricks_group_prefix}-user"
  allow_databricks_sql_access = true

  providers = {
    databricks.workspace = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE MODULE
##
## This module creates Databricks metastores and assigns them to Databricks Workspaces for Unity Catalog.
##
## Parameters:
## - `aws_s3_bucket_name`: AWS S3 bucket name.
## - `aws_s3_buckket_arn`: AWS S3 bucket ARN.
## - `databricks_storage_name`: Databricks Storage Credential Name.
## - `databricks_admin_group`: The name of the owner group for the Databricks metastore.
## - `databricks_workspace_number`: Databricks workspace number.
## - `databricks_metastore_grants`: List of Databricks Metastore specific grants to apply to admin group.
## - `databricks_catalog_grants`: List of Databricks Catalog specific grants to apply to admin group.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_metastore" {
  source   = "./modules/aws_databricks_metastore"

  aws_s3_bucket_name          = module.databricks_storage_configuration.aws_databricks_bucket_name
  aws_s3_bucket_arn           = module.databricks_storage_configuration.aws_databricks_bucket_arn
  databricks_storage_name     = "${var.aws_s3_bucket_name}-storage"
  databricks_admin_group      = module.databricks_admin_group.databricks_group_name
  databricks_workspace_number = databricks_mws_workspaces.this.workspace_id
  databricks_metastore_grants = local.databricks_metastore_grants
  databricks_catalog_grants   = local.databricks_catalog_grants
  databricks_catalog_name     = var.databricks_catalog_name
  
  providers = {
    aws.auth_session     = aws.auth_session
    databricks.accounts  = databricks.accounts
    databricks.workspace = databricks.workspace
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
  source   = "github.com/sim-parables/terraform-databricks//modules/databricks_secret_scope?ref=c05bc4f94a1167c550496f2f3565fa319f68bf8b"
  depends_on   = [ databricks_mws_workspaces.this ]

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
  source      = "github.com/sim-parables/terraform-databricks//modules/databricks_secret?ref=c05bc4f94a1167c550496f2f3565fa319f68bf8b"
  depends_on  = [ module.databricks_secret_scope ]
  
  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = var.aws_databricks_client_id_secret_name
  secret_data     = data.aws_caller_identity.current.user_id
  
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
  source       = "github.com/sim-parables/terraform-databricks//modules/databricks_secret?ref=c05bc4f94a1167c550496f2f3565fa319f68bf8b"
  depends_on   = [ module.databricks_secret_scope ]
  
  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = var.aws_databricks_client_secret_secret_name
  secret_data     = aws_iam_access_key.this.secret

  providers = {
    databricks.workspace = databricks.workspace
  }
}



terraform{
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "sim-parables"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "ci-cd-aws-workspace"
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS PROVIDER
##
## Configures the AWS provider with CLI Credentials.
## ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  alias = "accountgen"
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
  prefix             = "${random_string.this.id}-${local.program}-${local.project}"
  secret_scope       = upper(local.cloud)
  client_id_name     = "${local.prefix}-sp-client-id"
  client_secret_name = "${local.prefix}-sp-client-secret"
  catalog_name       = "${local.project}_catalog"
  schema_name        = "db_terraform"
  
  assume_role_policies = [
    {
      effect = "Allow"
      actions = [
        "sts:AssumeRoleWithWebIdentity"
      ]
      principals = [{
        type        = "Federated"
        identifiers = [var.OIDC_PROVIDER_ARN]
      }]
      conditions = [
        {
          test     = "StringLike"
          variable = "token.actions.githubusercontent.com:sub"
          values = [
            "repo:${var.GITHUB_REPOSITORY}:ref:${var.GITHUB_REF}"
          ]
        },
        {
          test     = "ForAllValues:StringEquals"
          variable = "token.actions.githubusercontent.com:iss"
          values = [
            "https://token.actions.githubusercontent.com",
          ]
        },
        {
          test     = "ForAllValues:StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values = [
            "sts.amazonaws.com",
          ]
        },
      ]
    },
    {
      effect = "Allow"
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = [module.aws_service_account.service_account_arn]
      }]
      conditions = []
    }
  ]

  service_account_roles_list = [
    "iam:*",
    "secretsmanager:*",
    "ec2:*",
    "kms:*",
    "s3:*"
  ]

  metastore_grants = [
    "CREATE_CATALOG", "CREATE_CONNECTION", "CREATE_EXTERNAL_LOCATION", 
    "CREATE_STORAGE_CREDENTIAL",
  ]

  catalog_grants = [
    "CREATE_SCHEMA", "CREATE_FUNCTION", "CREATE_TABLE", "CREATE_VOLUME", 
    "USE_CATALOG", "USE_SCHEMA", "READ_VOLUME", "SELECT",
  ]

  # Define Spark environment variables
  spark_env_variables      = {
    "CLOUD_PROVIDER": upper(local.cloud),
    "RAW_DIR": module.databricks_workspace.databricks_external_location_url,
    "OUTPUT_DIR": module.databricks_workspace.databricks_external_location_url,
    "SERVICE_ACCOUNT_CLIENT_ID": "spark.hadoop.fs.s3a.access.key",
    "SERVICE_ACCOUNT_CLIENT_SECRET": "spark.hadoop.fs.s3a.secret.key"
  }

  spark_conf_variables     = {
    "spark.hadoop.fs.s3a.endpoint": "s3.amazonaws.com",
    "spark.hadoop.fs.s3a.access.key": "{{secrets/${module.databricks_workspace.databricks_secret_scope_id}/${module.databricks_workspace.databricks_service_account_client_id_secret_name}}}",
    "spark.hadoop.fs.s3a.secret.key": "{{secrets/${module.databricks_workspace.databricks_secret_scope_id}/${module.databricks_workspace.databricks_service_account_client_secret_secret_name}}}",
    "spark.hadoop.fs.s3a.aws.credentials.provider": "org.apache.hadoop.fs.s3a.BasicAWSCredentialsProvider",
    "spark.hadoop.fs.s3a.server-side-encryption-algorithm": "SSE-KMS",
    "spark.databricks.driver.strace.enabled": "true"
  }

  databricks_cluster_library_files = [
    {
      file_name      = "hadoop-aws_3.3.4.jar"
      content_base64 = data.http.hadoop_aws_jar.response_body_base64
    },
    {
      file_name      = "aws-java-sdk_1.12.552.jar"
      content_base64 = data.http.aws_java_sdk_jar.response_body_base64
    },
  ]

  databricks_aws_attributes = {
    attributes = {
        availability       = "SPOT_AZURE"
        first_on_demand    = 0
        spot_bid_max_price = -1
    }
  }

  tags = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}


##---------------------------------------------------------------------------------------------------------------------
## AWS SERVICE ACCOUNT MODULE
##
## This module provisions an AWS service account along with associated roles and security groups.
##
## Parameters:
## - `service_account_name`: The display name of the new AWS Service Account.
## - `service_account_path`: The new AWS Service Account IAM Path.
## - `roles_list`: List of IAM roles to bing to new AWS Service Account.
##---------------------------------------------------------------------------------------------------------------------
module "aws_service_account" {
  source = "github.com/sim-parables/terraform-aws-service-account.git?ref=a18e50b961655a345a7fd2d8e573fe84484c7235"

  service_account_name = var.service_account_name
  service_account_path = var.service_account_path
  roles_list           = local.service_account_roles_list

  providers = {
    aws.accountgen = aws.accountgen
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS PROVIDER
##
## Configures the AWS provider with new Service Account Authentication.
## ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  alias = "auth_session"

  access_key = module.aws_service_account.access_id
  secret_key = module.aws_service_account.access_token
}

##---------------------------------------------------------------------------------------------------------------------
## AWS IDENTITY FEDERATION ROLES MODULE
##
## This module configured IAM Trust policies to provide OIDC federated access from Github Actions to AWS.
##
## Parameters:
## - `assume_role_policies`: List of OIDC trust policies.
##---------------------------------------------------------------------------------------------------------------------
module "aws_identity_federation_roles" {
  source     = "github.com/sim-parables/terraform-aws-service-account.git?ref=a18e50b961655a345a7fd2d8e573fe84484c7235//modules/identity_federation_roles"
  depends_on = [module.aws_service_account]

  assume_role_policies  = local.assume_role_policies
  service_account_group = module.aws_service_account.group_name
  policy_roles_list = [
    "iam:DeleteRole",
    "iam:ListInstanceProfilesForRole",
    "iam:ListAttachedRolePolicies",
    "iam:ListRolePolicies",
    "iam:GetRole",
    "iam:CreateRole",
    "iam:GetRolePolicy",
    "iam:PutRolePolicy",
    "iam:DeleteRolePolicy",
    "iam:CreatePolicyVersion",
    "iam:DeletePolicyVersion",
    "s3:Get*",
    "s3:Put*",
    "s3:List*",
    "kms:GenerateDataKey*",
    "kms:Encrypt",
    "kms:Decrypt",
  ]

  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS PROVIDER
##
## Configures the Databricks provider with authentication session to Databricks Accounts Portal.
##
## Parameters:
## - `alias`: Provdier Alias to Databricks Accounts
## - `profile`: The Databricks CLI profile used for authentication.
## ---------------------------------------------------------------------------------------------------------------------
provider "databricks" {
  alias   = "accounts"
  profile = var.DATABRICKS_CLI_PROFILE
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS WORKSPACE MODULE
##
## Provision a Databricks Workspace on AWS configured with Unity Catalog attached to Databricks Accounts. Supplied with
## external storage stored in AWS S3 Bucket authenticated with STS IAM Cross Account Policy.
##
## Parameters:
## - `DATABRICKS_ACCOUNT_ID`: Databricks Accounts Account ID.
## - `DATABRICKS_ADMINISTRATOR`: Databricks Accounts administrator email.
## - `aws_s3_bucket_name`: AWS S3 bucket name for Databricks MWS and Unity Catalog.
## - `aws_kms_key_name`: AWS KMS Key name.
## - `aws_databricks_iam_role_name`: AWS IAM Role name for Databricks Policies.
## - `aws_databricks_client_id_secret_name`: AWS Client ID secret name for KMS and Databricks Secret.
## - `aws_databricks_client_secret_secret_name`: AWS Client Secret secret name for KMS and Databricks Secret.
## - `aws_databricks_vpc_name`: AWS Databricks MWS VPC name.
## - `databricks_workspace_name`: Databricks Workspace name.
## - `databricks_catalog_name`: Databricks Unity Catalog name.
## - `databricks_catalog_grants`: List of Databricks Catalog grants to apply to admin group.
## - `databricks_metastore_grants`: List of Datbricks Metastore grants to apply to admin group.
## - `tags`: AWS tags.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_workspace" {
  source = "../"
  
  DATABRICKS_ACCOUNT_ID                    = var.DATABRICKS_ACCOUNT_ID
  DATABRICKS_ADMINISTRATOR                 = var.DATABRICKS_ADMINISTRATOR
  aws_s3_bucket_name                       = "${local.prefix}-bucket"
  aws_kms_key_name                         = "${local.prefix}-kms-key"
  aws_databricks_iam_role_name             = "${local.prefix}-iam-role"
  aws_databricks_client_id_secret_name     = "${local.prefix}-sp-client-id"
  aws_databricks_client_secret_secret_name = "${local.prefix}-sp-client-secret"
  aws_databricks_vpc_name                  = "${local.prefix}-vpc"
  databricks_workspace_name                = "${local.prefix}-workspace"
  databricks_catalog_name                  = "${local.prefix}-catalog"
  databricks_catalog_grants                = local.catalog_grants
  databricks_metastore_grants              = local.metastore_grants
  tags                                     = local.tags

  providers = {
    aws.auth_session    = aws.auth_session
    databricks.accounts = databricks.accounts
  }
}


provider "databricks" {
  alias = "workspace"
  host  = module.databricks_workspace.databricks_host
  token = module.databricks_workspace.databricks_token
}


## ---------------------------------------------------------------------------------------------------------------------
## HTTP DATA SOURCE
## 
## Download contents of hadoop-aws-3.3.4 jar Databricks Unity Catalog LIBRARIES Volume.
## 
## Parameters:
## - `url`: Sample data URL.
## - `request_headers`: Mapping of HTTP request headers.
## ---------------------------------------------------------------------------------------------------------------------
data "http" "hadoop_aws_jar" {
  url = "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar"

  # Optional request headers
  request_headers = {
    Accept  = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    Accept-Encoding = "gzip, deflate, br, zstd"
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## HTTP DATA SOURCE
## 
## Download contents of aws-java-sdk-1.12.552 jar Databricks Unity Catalog LIBRARIES Volume.
## 
## Parameters:
## - `url`: Sample data URL.
## - `request_headers`: Mapping of HTTP request headers.
## ---------------------------------------------------------------------------------------------------------------------
data "http" "aws_java_sdk_jar" {
  url = "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk/1.12.552/aws-java-sdk-1.12.552.jar"

  # Optional request headers
  request_headers = {
    Accept  = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    Accept-Encoding = "gzip, deflate, br, zstd"
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS WORKSPACE CONFIG MODULE
## 
## This module configures a Databricks Workspace with the resources necessary to start utilizing spark/azure compute,
## and a bootstrapped Unity Catalog. Databricks Assets Bundles will also be ready to deploy onto the workspace with 
## pytest scripts ready to test spark capabilities.
## 
## Parameters:
## - `DATABRICKS_CLUSTERS`: Number of clusters to deploy in Databricks Workspace.
## - `databricks_cluster_name`: Prefix for Databricks Clusters. 
## - `databricks_catalog_name`: Name of Databricks Unity Catalog.
## - `databricks_catalog_external_location_url`: Cloud Storage URL.
## - `databricks_cluster_spark_env_variable`: Map of Spark environment variables to assign to Databricks cluster.
## - `databricks_cluster_spark_conf_variable`: Map of Spark configuration variables to assign to Databricks cluster.
## - `databricks_cluster_library_files`: List of Databricks Unity Catalog Library Files to upload for install.
## - `databricks_workspace_group`: Databricks Workspace group to create for cluster policy permission.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_workspace_config" {
  source   = "github.com/sim-parables/terraform-databricks?ref=c05bc4f94a1167c550496f2f3565fa319f68bf8b"
  depends_on = [ module.databricks_workspace ]
  
  DATABRICKS_CLUSTERS                      = var.DATABRICKS_CLUSTERS
  databricks_cluster_name                  = "${local.prefix}-cluster"
  databricks_catalog_name                  = module.databricks_workspace.databricks_catalog_name
  databricks_schema_name                   = local.schema_name
  databricks_catalog_external_location_url = module.databricks_workspace.databricks_external_location_url
  databricks_cluster_spark_env_variable    = local.spark_env_variables
  databricks_cluster_spark_conf_variable   = local.spark_conf_variables
  databricks_cluster_library_files         = local.databricks_cluster_library_files
  #databricks_cluster_azure_attributes      = local.databricks_azure_attributes
  databricks_workspace_group               = "${local.prefix}-group"

  providers = {
    databricks.accounts = databricks.accounts
    databricks.workspace = databricks.workspace
  }
}


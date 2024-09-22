<p float="left">
  <img id="b-0" src="https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white" height="25px"/>
  <img id="b-1" src="https://img.shields.io/badge/Amazon_AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white" height="25px"/>
</p>

# Terraform AWS Databricks Workspace & Unity Catalog Module

A reusable module for creating & configuring Databricks Workspaces with Unity Catalog on Amazon Web Services.

> [!IMPORTANT]
> These terraform modules and CI/CD Workflow Actions will have associated costs when deployed to Amazon Web Services and kept
> running for any given duration. Please use with caution!

## Usage


| :memo: NOTE                            |
|:---------------------------------------|
| Usage documentation under Construction |


## Inputs

| Name                             | Description                             | Type           | Required |
|:---------------------------------|:----------------------------------------|:---------------|:---------|
| DATABRICKS_ADMINISTRATOR         | DB Accounts & Workspace Admin email     | String         | Yes      |
| DATABRICKS_ACCOUNT_ID            | Databricks Account ID                   | String         | Yes      |
| DATABRICKS_CLI_PROFILE           | Databricks Config Profile Name for GCP  | String         | No       |
| DATABRICKS_CLUSTERS              | Number of Databricks Workspace Clusters | Integer        | No       |
| databricks_workspace_name        | DB Workspace Name                       | String         | No       |


## Outputs

| Name                                                  | Description                                    |
|:------------------------------------------------------|:-----------------------------------------------|
| databricks_workspace_host                             | Databricks (DB) Workspace URL                  |
| databricks_workspace_id                               | DB Workspace ID                                |
| databricks_access_token                               | DB Workspace Access Token                      |
| databricks_workspace_name                             | DB Workspace Name                              |
| databricks_secret_scope                               | DB Workspace Secret Scope Name                 |
| databricks_service_account_client_id_secret_name      | DB Workspace Secret Name for SA Client ID      |
| databricks_service_account_private_key_id_secret_name | DB Workspace Secret Name for SA Private Key ID |
| databricks_service_account_private_key_secret_name    | DB Workspace Secret Name for SA Private Key    |
| databricks_external_location_url                      | DB Unity Catalog External Location GCS URL     |
| databricks_cluster_ids                                | List of DB Workspace Cluster IDs               |
| aws_kms_key_id                                        | AWS Key Management Services ID                 |
| aws_kms_secret_client_id_name                         | AWS KMS Secret Name for SP Client ID           |
| aws_kms_secret_client_secret_name                     | AWS KMS Secret Name for SP Client Secret       |


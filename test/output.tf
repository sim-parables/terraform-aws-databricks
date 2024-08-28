output "service_account_client_id" {
  description = "AWS Databricks Service Account Client ID"
  value = module.aws_service_account.access_id
}

output "service_account_client_secret" {
  description = "AWS Databricks Service Account Client Secret"
  value       = module.aws_service_account.access_token
  sensitive   = true
}

output "databricks_workspace_host" {
  description = "Databricks Workspace Host URL"
  value       = module.databricks_workspace.databricks_host
}

output "databricks_access_token" {
  description = "Databricks Personal Access Token"
  value       = module.databricks_workspace.databricks_token
  sensitive   = true
}

output "databricks_workspace_id" {
  description = "Databricks Workspace ID (Number Only)"
  value       = module.databricks_workspace.databricks_workspace_id
}

output "aws_kms_key_id" {
  description = "AWS KMS Encryption Key ID"
  value       = module.databricks_workspace.aws_kms_key_id
}

output "aws_kms_secret_client_id_name" {
  description = "AWS KMS Client ID Secret Name"
  value       = module.databricks_secrets.aws_kms_secret_client_id_name
}

output "aws_kms_secret_client_secret_name" {
  description = "AWS KMS Client Secret Secret Name"
  value       = module.databricks_secrets.aws_kms_secret_client_secret_name
}

output "databricks_secret_scope" {
  description = "Databricks Workspace Secret Scope"
  value       = module.databricks_secrets.databricks_secret_scope
}

output "databricks_service_account_client_id_secret_name" {
  description = "Databricks Workspace AWS Client ID Secret Name"
  value       = module.databricks_secrets.databricks_service_account_client_id_secret_name
}

output "databricks_service_account_client_secret_secret_name" {
  description = "Databricks Workspace AWS Client Secret Secret Name"
  value       = module.databricks_secrets.databricks_service_account_client_secret_secret_name
}

output "databricks_external_location_url" {
  description = "Databricks AWS Metastore Bucket s3 URL"
  value       = module.databricks_metastore.databricks_external_location_url
}

output "databricks_cluster_ids" {
  description = "List of Databricks Workspace Cluster IDs"
  value       = module.databricks_workspace_config.databricks_cluster_ids
}

output "databricks_example_holdings_data_path" {
  description = "Databricks Example Holding Data Unity Catalog File Path"
  value       = module.databricks_workspace_config.databricks_example_holdings_data_path
}

output "databricks_example_weather_data_path" {
  description = "Databricks Example Weather Data Unity Catalog File Path"
  value       = module.databricks_workspace_config.databricks_example_weather_data_path
}

output "databricks_unity_catalog_table_paths" {
  description = "Databricks Unity Catalog Table Paths"
  value       = module.databricks_workspace_config.databricks_unity_catalog_table_paths
}
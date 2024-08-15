output "databricks_host" {
  value = module.databricks_workspace.databricks_host
}

output "databricks_token" {
  value     = module.databricks_workspace.databricks_token
  sensitive = true
}

output "databricks_workspace_id" {
  description = "Databricks Workspace ID (Number Only)"
  value       = module.databricks_workspace.databricks_workspace_id
}

output "databricks_secret_scope" {
  description = "Databricks Workspace Secret Scope"
  value       = module.databricks_workspace.databricks_secret_scope
}

output "databricks_service_account_client_id_secret_name" {
  description = "Databricks Workspace AWS Client ID Secret Name"
  value       = module.databricks_workspace.databricks_service_account_client_id_secret_name
}

output "databricks_service_account_client_secret_secret_name" {
  description = "Databricks Workspace AWS Client Secret Secret Name"
  value       = module.databricks_workspace.databricks_service_account_client_secret_secret_name
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
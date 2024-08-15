output "databricks_host" {
  value = databricks_mws_workspaces.this.workspace_url
}

output "databricks_token" {
  value     = databricks_mws_workspaces.this.token[0].token_value
  sensitive = true
}

output "databricks_workspace_id" {
  description = "Databricks Workspace ID (Number Only)"
  value       = databricks_mws_workspaces.this.workspace_id
}

output "databricks_external_location_url" {
  description = "Databricks Azure Metastore Bucket abfss URL"
  value       = module.databricks_metastore.databricks_external_location_url
}

output "databricks_catalog_name" {
  description = "Databricks Catalog Name"
  value       = module.databricks_metastore.databricks_catalog_name
}

output "databricks_secret_scope" {
  description = "Databricks Workspace Secret Scope"
  value       = module.databricks_secret_scope.databricks_secret_scope
}

output "databricks_secret_scope_id" {
  description = "Databricks Workspace Secret Scope ID"
  value       = module.databricks_secret_scope.databricks_secret_scope_id
}

output "databricks_service_account_client_id_secret_name" {
  description = "Databricks Workspace AWS Client ID Secret Name"
  value       = module.databricks_service_account_key_name_secret.databricks_secret_name
}

output "databricks_service_account_client_secret_secret_name" {
  description = "Databricks Workspace AWS Client Secret Secret Name"
  value       = module.databricks_service_account_key_data_secret.databricks_secret_name
}
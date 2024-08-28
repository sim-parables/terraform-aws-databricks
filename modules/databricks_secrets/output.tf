output "databricks_secret_scope" {
  description = "Databricks Workspace Secret Scope"
  value       = module.databricks_secret_scope.databricks_secret_scope
}

output "databricks_secret_scope_id" {
  description = "Databricks Workspace Secret Scope ID"
  value       = module.databricks_secret_scope.databricks_secret_scope_id
}

output "aws_kms_secret_client_id_name" {
  description = "AWS KMS Client ID Secret Name"
  value       = module.aws_secret_client_id.secret_name
}

output "aws_kms_secret_client_secret_name" {
  description = "AWS KMS Client Secret Secret Name"
  value       = module.aws_secret_client_secret.secret_name
}

output "databricks_service_account_client_id_secret_name" {
  description = "Databricks Workspace AWS Client ID Secret Name"
  value       = module.databricks_service_account_key_name_secret.databricks_secret_name
}

output "databricks_service_account_client_secret_secret_name" {
  description = "Databricks Workspace AWS Client Secret Secret Name"
  value       = module.databricks_service_account_key_data_secret.databricks_secret_name
}
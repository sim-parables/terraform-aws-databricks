output "metastore_name" {
  description = "AWS Databricks Metastore Name"
  value       = var.databricks_storage_name
}

output "storage_credential_id" {
  description = "Azure Databricks Storage Credential ID"
  value       = databricks_storage_credential.this.id
}

output "databricks_external_location_url" {
  description = "Databricks AWS Metastore Bucket s3 URL"
  value       = module.databricks_external_location.databricks_external_location_url
}

output "databricks_catalog_name" {
  description = "Databricks Catalog Name"
  value       = module.databricks_external_location.databricks_catalog_name
}

output "databricks_service_principal_id" {
  description = "Databricks Service Principal ID"
  value       = databricks_service_principal.this.application_id
}

output "databricks_service_principal_token" {
  description = "Databricks Service Principal Personal Access Token"
  value       = databricks_obo_token.this.token_value
  sensitive   = true
}
output "metastore_name" {
  description = "AWS Databricks Metastore Name"
  value       = var.databricks_storage_name
}

output "storage_credential_id" {
  description = "Azure Databricks Storage Credential ID"
  value       = databricks_storage_credential.this.id
}

output "databricks_external_location_url" {
  description = "Databricks Azure Metastore Bucket abfss URL"
  value       = module.databricks_external_location.databricks_external_location_url
}

output "databricks_catalog_name" {
  description = "Databricks Catalog Name"
  value       = module.databricks_external_location.databricks_catalog_name
}
output "aws_databricks_bucket_name" {
  description = "AWS S3 Databricks External Storage Bucket Name"
  value       = module.databricks_storage_configuration.aws_databricks_bucket_name
}

output "aws_databricks_bucket_arn" {
  description = "AWS S3 Databricks External Storage Bucket Name"
  value       = module.databricks_storage_configuration.aws_databricks_bucket_arn
}

output "aws_kms_key_id" {
  description = "AWS KMS Encryption Key ID"
  value       = module.aws_kms_key.kms_key_id
}

output "aws_kms_key_arn" {
  description = "AWS KMS Encryption Key ARN"
  value       = module.aws_kms_key.kms_key_arn
}

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
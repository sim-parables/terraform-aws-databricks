output "storage_configuration_id" {
  description = "AWS S3 Bucket Configuration ID"
  value       = databricks_mws_storage_configurations.this.storage_configuration_id
}

output "aws_databricks_bucket_name" {
  description = "AWS Bucket for Databricks S3 Storage Requirements and Coniguration"
  value       = module.databricks_bucket.bucket_id
}

output "aws_databricks_bucket_arn" {
  description = "AWS Bucket for Databricks S3 Storage Requirements and Coniguration"
  value       = module.databricks_bucket.bucket_arn
}
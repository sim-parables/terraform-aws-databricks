output "credentials_id" {
  description = "AWS Databrick IAM Role Credentials ID"
  value       = databricks_mws_credentials.this.credentials_id
}

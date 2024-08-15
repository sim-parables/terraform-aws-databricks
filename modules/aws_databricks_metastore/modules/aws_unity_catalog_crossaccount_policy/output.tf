output "databricks_metastore_data_access_policy_name" {
    description = "Databricks Meta Store Data Access Policy Name"
    value       = aws_iam_role.this.name
}

output "databricks_metastore_data_access_policy_arn" {
    description = "Databricks Meta Store Data Access Policy ARN"
    value       = aws_iam_role.this.arn
}

output "databricks_metastore_cross_account_policy_arn" {
    description = "Databricks Meta Store Cross Account Policy ARN (Statically Types)"
    value       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.databricks_unity_catalog_role_name}-role"
}
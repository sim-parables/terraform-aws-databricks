output "network_id" {
  description = "AWS VPC Databricks Network ID"
  value       = databricks_mws_networks.this.network_id
}
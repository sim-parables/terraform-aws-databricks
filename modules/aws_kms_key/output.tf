output "kms_key_arn" {
  description = "AWS KMS Key ARN"
  value       = aws_kms_key.this.arn
}

output "kms_key_id" {
  description = "AWS KMS Key ID"
  value       = aws_kms_key.this.key_id
}
output "s3_bucket_name" {
  value = aws_s3_bucket.this.bucket_domain_name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.dynamodb-terraform-state-locking.name
}
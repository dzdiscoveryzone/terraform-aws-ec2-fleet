output "s3_bucket_name" {
  value = aws_s3_bucket.this.bucket_domain_name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.dynamodb-terraform-state-locking.name
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.dynamodb-terraform-state-locking.arn
}
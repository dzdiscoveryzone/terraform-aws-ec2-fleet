resource "aws_kms_key" "this" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = var.deletion_window_in_days

  tags = merge({
    "Name" : format("%v-%v-tfstate-kms-key", var.default_tags["Environment"], var.bucket_name)
  }, var.default_tags)
}

resource "aws_s3_bucket" "this" {
  region = var.region
  bucket = var.bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.this.arn
        sse_algorithm     = var.sse_algorithm
      }
    }
  }
  tags = merge({
    "Name" : format("%v-%v-tfstate-s3", var.default_tags["Environment"], var.bucket_name)
  }, var.default_tags)
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "dynamodb-terraform-state-locking" {
  name           = var.dynamodb_table_name
  hash_key       = "LockID"
  read_capacity  = 10
  write_capacity = 10

  attribute {
    name = "LockID"
    type = "S"
  }
  tags = merge({
    "Name" : format("%v-%v", var.default_tags["Environment"], var.dynamodb_table_name)
  }, var.default_tags)
}
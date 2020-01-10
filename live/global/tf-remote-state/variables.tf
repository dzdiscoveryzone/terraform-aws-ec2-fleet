variable "deletion_window_in_days" {
  description = "amount of days to keep the KMS key after deletion"
  type        = number
  default     = 10
}

variable "bucket_name" {
  description = "Name of S3 bucket that holds the terraform state file"
  type        = string
  default     = ""
}

variable "sse_algorithm" {
  description = "Algorithm to use for encryption of the S3 bucket. In this scenario it is the AWS KMS"
  type        = string
  default     = "aws:kms"
}

variable "dynamodb_table_name" {
  description = "Name of the table, must be unique in the deployed to region"
  type        = string
  default     = ""
}

variable "dynamodb_table_hask_key" {
  description = "The attribute to use as the hash (partition) key"
  type        = string
  default     = ""
}

variable "dynamodb_table_read_capacity" {
  description = "The number of read units for this table"
  type        = number
  default     = 10
}

variable "dynamodb_table_write_capacity" {
  description = "The number of write units for this table"
  type        = number
  default     = 10
}

variable "default_tags" {
  description = "Default tags for all resources required for the terraform remote state S3 backend"
  type        = map(string)
  default = {
    "Environment" : "dev"
  }
}
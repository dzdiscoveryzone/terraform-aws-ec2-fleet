variable "parent_account_id" {
  description = "The parent account which will be assuming this IAM role"
  type        = string
  default     = ""
}

variable "s3_actions" {
  description = "Permissions to apply to the IAM role which will be responsible for interacting with this S3 bucket where the tfstate file is stored"
  type        = list(string)
  default     = []
}

variable "s3_resource_list" {
  description = "S3 bucket ARN that the policy will apply to for CI/CD"
  type        = list(string)
  default     = []
}

variable "dynamodb_actions" {
  description = "Permissions to apply to the IAM role which will be responble for interacting with this DynamoDB table for terraform state locking"
  type        = list(string)
  default     = []
}

variable "dynamodb_tables" {
  description = "DynamoDB Table used for terraform state locking"
  type        = list(string)
  default     = []
}

variable "iam_role_count" {
  description = "Number of IAM roles to deploy"
  type        = number
  default     = 1
}

variable "iam_role_name" {
  description = "Name  for IAM Role"
  type        = string
  default     = ""
}

variable "iam_policy_name" {
  description = ""
}
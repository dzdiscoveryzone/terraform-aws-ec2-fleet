output "iam_role_arn" {
  value = aws_iam_role.tf_deployer.*.arn
}

output "iam_role_name" {
  value = aws_iam_role.tf_deployer.*.name
}

output "iam_role_policy" {
  value = aws_iam_policy.this.policy
}
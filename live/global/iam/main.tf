resource "aws_iam_role" "tf_deployer" {
  count = var.iam_role_count

  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.parent_account.json
}

resource "aws_iam_policy" "this" {
  name        = var.iam_policy_name
  description = "A policy to allow terraform to deploy and manage EC2 Instance, VPC's, S3 buckets, and DynamoDB Tables"
  policy      = data.aws_iam_policy_document.tf_deploy.json
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(aws_iam_role.tf_deployer)

  role       = aws_iam_role.tf_deployer[count.index].name
  policy_arn = aws_iam_policy.this.arn
}

data "aws_iam_policy_document" "parent_account" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.parent_account_id}:root"]
    }
  }
}

data "aws_iam_policy_document" "tf_deploy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]

    resources = var.s3_resource_list
  }

  statement {
    effect  = "Allow"
    actions = var.s3_actions

    resources = var.s3_resource_list
  }

  statement {
    effect  = "Allow"
    actions = var.dynamodb_actions

    resources = var.dynamodb_tables
  }
}

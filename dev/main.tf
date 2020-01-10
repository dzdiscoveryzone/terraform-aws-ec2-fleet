provider "aws" {
  version = "~> 2.40"
  region  = var.region
}

terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket         = "fake-bucket"
    key            = "terraform.tfstate"
    region         = "random-region"
    encrypt        = true
    dynamodb_table = "fake-dynamo-table"
  }
}

module "vpc" {
  source               = "../modules/vpc"
  cidr_block           = "172.24.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  has_multiple_subnets = true
  private_subnet_count = 0
  public_subnet_count  = 1
  enable_dns_hostnames = true
  default_tags         = var.default_tags
}

resource "aws_instance" "web" {
  count = var.ec2_count

  ami           = lookup(var.amis, var.region)
  instance_type = var.instance_type
  subnet_id     = element(module.vpc.public_subnet_ids, count.index)
  key_name      = var.ssh_key_name

  tags = merge(map(
    "Name", format("${var.ec2_name}-%s-${count.index}", var.default_tags["Environment"]),
    ),
  var.default_tags)

  security_groups = [aws_security_group.this.id]

  depends_on = [aws_security_group.this]
}

resource "aws_ebs_volume" "this" {
  count = var.ec2_count * var.ebs_count

  availability_zone = length(module.vpc.public_subnet_ids) > length(module.vpc.availibility_zones) ? element(aws_instance.web.*.availability_zone, count.index) + 1 : element(aws_instance.web.*.availability_zone, count.index)
  size              = var.ebs_volume_size

  tags = merge(map(
    "Name", format("${var.ec2_name}-%s-ebs-${count.index}", var.default_tags["Environment"]),
    ),
  var.default_tags)
}

resource "aws_volume_attachment" "this" {
  count = var.ec2_count * var.ebs_count

  volume_id   = aws_ebs_volume.this.*.id[count.index]
  device_name = element(var.ebs_device_names, count.index)
  instance_id = element(aws_instance.web.*.id, count.index)
}

resource "aws_security_group" "this" {
  name        = format("${var.ec2_name}-%s-sg", var.default_tags["Environment"])
  description = "Inbound Security Group for SSH"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.ingress_cidr_blocks
    }
  }

  tags = merge(map(
    "Name", format("${var.ec2_name}-%s-sg", var.default_tags["Environment"]),
    ),
  var.default_tags)
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}
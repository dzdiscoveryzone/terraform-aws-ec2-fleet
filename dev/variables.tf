variable "region" {
  type        = string
  description = "Default instance for the VPC"
  default     = ""
}

variable "amis" {
  type = map(string)

  default = {
    us-east-1 = ""
    us-east-2 = ""
  }
}

variable "ec2_count" {
  description = "Amount of EC2 web isntances to deploy"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "Instance size, default is t2.micro (free tier)"
  type        = string
  default     = "t3.micro"
}

variable "ssh_key_name" {
  description = "SSH Key Name in AWS that will be used to access the EC2 Instance"
  type        = string
  default     = ""
}

variable "ec2_name" {
  description = "Name for EC2 Instance. This will be formatted to append different values as well such as Environment; e.g. web-dev-1"
  type        = string
  default     = ""
}

variable "default_tags" {
  description = "Default tags used for all resources. This is to better consolidate billing"
  type        = map(string)

  default = {
    "Business Unit" = ""
  }
}

variable "ebs_count" {
  description = "Number of EBS Volumes to deploy and attach onto the EC2 Instance"
  type        = number
  default     = 3
}

variable "ebs_volume_size" {
  description = "Size of the EBS Volume"
  type        = number
  default     = 30
}

variable "ebs_device_names" {
  description = "List of device names to attach multiple EBS volumes to EC2 Instance"
  type        = list(string)
  default = [
    "/dev/sdd",
    "/dev/sde",
    "/dev/sdf",
  ]
}

variable "ingress_ports" {
  description = "List of ingress ports to be allowed"
  default     = []
}

variable "ingress_cidr_blocks" {
  description = "Inbound CIDR Blocks"
  default     = []
}
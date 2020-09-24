variable "region" {
  description = "Default instance for the VPC"
  type        = string
  default     = ""
}

variable "create_vpc" {
  description = "Determines whether to create the VPC"
  type        = bool
  default     = false
}

variable "cidr_block" {
  description = "Default CIDR Block"
  type        = string
  default     = ""
}

variable "availability_zones" {
  description = "AZs for Subnets"
  type        = list(string)
  default     = []
}

variable "public_subnet" {
  description = "Public subnet(s) to launch inside VPC"
  type        = list(string)
  default     = []
}

variable "private_subnet" {
  description = "Private subnet(s) to launch inside VPC"
  type        = list(string)
  default     = []
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = false
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Set this to true to enable a public IP when a resource is added to this Subnet"
  type        = bool
  default     = true
}

variable "default_tags" {
  description = "Default tags to apply"
  type        = map(any)
  default = {
    Environment = "dev"
    "Is Production" : null
  }
}

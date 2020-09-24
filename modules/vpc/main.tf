resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_classiclink   = "false"

  tags = merge({
    Name = format("%v-vpc", var.default_tags["Environment"])
  }, var.default_tags)
}

resource "aws_subnet" "public" {
  count = var.create_vpc && length(var.public_subnet) > 0 ? length(var.public_subnet) : 0

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(concat(var.public_subnet, [""]), count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone       = element(var.availability_zones, count.index)

  tags = merge({
    Name = format("public-subnet-%v", element(var.availability_zones, count.index))
  }, var.default_tags)
}

resource "aws_subnet" "private" {
  count = var.create_vpc && length(var.private_subnet) > 0 ? length(var.private_subnet) : 0

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(concat(var.private_subnet, [""]), count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch ? false : true
  availability_zone       = element(var.availability_zones, count.index)

  tags = merge({
    Name = format("private-subnet-%v", element(var.availability_zones, count.index))
  }, var.default_tags)
}

# Internet GW
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge({
    Name = "internet-gw"
  }, var.default_tags)
}

// EIP required for NAT GW
resource "aws_eip" "this" {
  count = var.create_vpc && length(var.private_subnet) > 0 ? length(var.private_subnet) : 0
}

// NAT GW must reside inside the public Subnet
resource "aws_nat_gateway" "private" {
  count = var.create_vpc && length(var.private_subnet) > 0 ? length(var.private_subnet) : 0

  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.this.*.id, count.index)
}

// private route table
resource "aws_route_table" "private" {
  count = var.create_vpc && length(var.private_subnet) > 0 ? length(var.private_subnet) : 0

  vpc_id = aws_vpc.this.id

  tags = merge({
    Name = format("private-subnet-route-table-%v", element(var.availability_zones, count.index))
  }, var.default_tags)
}

// route is it's own resource for better modularity
resource "aws_route" "ngw" {
  count = var.create_vpc && length(var.private_subnet) > 0 ? length(var.private_subnet) : 0

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.private.*.id, count.index)

  timeouts {
    create = "5m"
  }

  depends_on = [aws_route_table.private]
}

// associate public subnet(s) with route table above
resource "aws_route_table_association" "private" {
  count = var.create_vpc && length(var.private_subnet) > 0 ? length(var.private_subnet) : 0

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

// public route tables
resource "aws_route_table" "public" {
  count = var.create_vpc && length(var.public_subnet) > 0 ? length(var.public_subnet) : 0

  vpc_id = aws_vpc.this.id

  tags = merge({
    Name = format("public-subnet-route-table-%v", element(var.availability_zones, count.index))
  }, var.default_tags)
}

resource "aws_route" "igw" {
  count = var.create_vpc && length(var.public_subnet) > 0 ? length(var.public_subnet) : 0

  route_table_id         = element(aws_route_table.public.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  timeouts {
    create = "5m"
  }

  depends_on = [aws_route_table.public]
}

# associate public subnet(s) with route table above
resource "aws_route_table_association" "public" {
  count = var.create_vpc && length(var.public_subnet) > 0 ? length(var.public_subnet) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}

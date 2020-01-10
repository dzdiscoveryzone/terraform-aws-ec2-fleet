output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "availibility_zones" {
  value = var.availability_zones
}

output "public_subnet_tags" {
  value = aws_subnet.public.*.tags
}
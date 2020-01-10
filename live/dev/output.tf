output "ec2_instance_id" {
  value = aws_instance.web.*.id[0]
}

output "public_ip" {
  value = aws_instance.web.*.public_ip
}

output "private_ip" {
  value = aws_instance.web.*.private_ip
}

output "sg_id" {
  value = aws_security_group.this.id
}
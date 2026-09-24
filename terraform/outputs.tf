output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "web_security_group_id" {
  description = "ID of the web/app security group."
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "ID of the application EC2 instance."
  value       = var.create_ec2_instance ? aws_instance.app[0].id : null
}

output "instance_public_ip" {
  description = "Elastic IP address of the application host. Point your domain's A record here."
  value       = var.create_ec2_instance ? aws_eip.app[0].public_ip : null
}

output "route53_zone_id" {
  description = "Hosted zone ID - copy the NS records from this zone to your domain registrar."
  value       = var.domain_name != "" ? aws_route53_zone.primary[0].zone_id : null
}

output "route53_name_servers" {
  description = "Name servers to set at your domain registrar."
  value       = var.domain_name != "" ? aws_route53_zone.primary[0].name_servers : null
}

output "ssh_command" {
  description = "Convenience SSH command for the beginner deployment path."
  value       = var.create_ec2_instance ? "ssh ubuntu@${aws_eip.app[0].public_ip}" : null
}

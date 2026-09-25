# Creates a public hosted zone for var.domain_name and points the apex
# record at the EC2 instance's Elastic IP. Registering the domain itself
# happens outside Terraform (with your registrar or Route 53 domain
# registration) - see docs/domain-dns-guide.md.

resource "aws_route53_zone" "primary" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name

  tags = {
    Name = "${var.project_name}-hosted-zone"
  }
}

resource "aws_route53_record" "app_a" {
  count   = var.domain_name != "" && var.create_ec2_instance ? 1 : 0
  zone_id = aws_route53_zone.primary[0].zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.app[0].public_ip]
}

resource "aws_route53_record" "app_www" {
  count   = var.domain_name != "" && var.create_ec2_instance ? 1 : 0
  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.domain_name]
}

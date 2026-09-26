variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Short name used as a prefix for resource names/tags."
  type        = string
  default     = "dream-vacations"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "availability_zones" {
  description = "AZs to spread public subnets across. Leave empty to auto-select the first N AZs in the region."
  type        = list(string)
  default     = []
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into the EC2 instance. Restrict this to your own IP (e.g. 203.0.113.10/32) in production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type for the application host."
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair used for SSH access."
  type        = string
}

variable "domain_name" {
  description = "Root domain name to manage in Route 53 (e.g. example.com). Leave blank to skip creating a hosted zone."
  type        = string
  default     = ""
}

variable "create_ec2_instance" {
  description = "Whether to provision the EC2 instance for the beginner (SSH + docker compose) deployment path."
  type        = bool
  default     = true
}

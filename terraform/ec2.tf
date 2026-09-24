# Beginner deployment path: a single EC2 instance running Docker + Docker
# Compose, reachable over SSH, fronted by an Elastic IP so the Route 53 A
# record stays valid across instance stop/start.

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app" {
  count                       = var.create_ec2_instance ? 1 : 0
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  # Installs Docker + Compose on first boot so the instance is ready for
  # `git clone` + `docker compose up` (or scripts/deploy.sh) immediately.
  user_data = <<-EOF
    #!/usr/bin/env bash
    set -euo pipefail
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg git
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker ubuntu
  EOF

  tags = {
    Name = "${var.project_name}-app-host"
  }
}

resource "aws_eip" "app" {
  count    = var.create_ec2_instance ? 1 : 0
  instance = aws_instance.app[0].id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-app-eip"
  }
}

# Deployment Guide (Beginner Path: EC2 + Docker Compose + Nginx + Certbot)

Takes the repo from `git clone` to a live app at `https://yourdomain.com`.
Read `docs/domain-dns-guide.md` first if you don't have a domain yet.

## 0. Prerequisites

- AWS account with credentials configured locally (`aws configure`)
- An EC2 key pair:
  ```bash
  aws ec2 create-key-pair --key-name dream-vacations-key \
    --query 'KeyMaterial' --output text > dream-vacations-key.pem
  chmod 400 dream-vacations-key.pem
  ```
- Terraform >= 1.6 installed locally
- A registered domain

## 1. Bootstrap Terraform remote state (one-time)

```bash
aws s3api create-bucket --bucket dream-vacations-tfstate-<unique-suffix> --region us-east-1
aws s3api put-bucket-versioning --bucket dream-vacations-tfstate-<unique-suffix> \
  --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name dream-vacations-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-1
```

Update the bucket name in `terraform/backend.tf`, then:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: key_pair_name, ssh_allowed_cidr, domain_name, etc.
terraform init
terraform plan
terraform apply
```

```bash
terraform output instance_public_ip
terraform output route53_name_servers   # if domain_name was set
terraform output ssh_command
```

If you set `domain_name`, point your registrar at the printed name servers
now (see `docs/domain-dns-guide.md`) - DNS needs time to propagate.

## 2. Prepare the EC2 host

`user_data` already installed Docker + Compose on first boot.

```bash
ssh -i dream-vacations-key.pem ubuntu@$(terraform output -raw instance_public_ip)

git clone https://github.com/<you>/dream-vacation-capstone.git
cd dream-vacation-capstone
sudo ./scripts/setup-env.sh
cp .env.example .env
nano .env   # set a real POSTGRES_PASSWORD, etc.
```

## 3. Run the application stack

```bash
docker compose up -d --build
docker compose ps
curl -I http://localhost:8080
curl http://localhost:3001/api/health   # {"status":"ok","db":"connected"}
```

At this point the app works at `http://<elastic-ip>:8080`. The rest of this
guide puts it behind Nginx on 80/443 with your domain and SSL.

## 4. Install and configure Nginx as a reverse proxy

The frontend container's own Nginx already serves the React build and
proxies `/api/*` to the backend container over the Docker network, so the
host-level Nginx only needs to point at the frontend container's port:

```bash
sudo apt-get install -y nginx
sudo cp nginx/dream-vacations.conf /etc/nginx/sites-available/dream-vacations.conf
sudo sed -i "s/CHANGE-ME.example.com/yourdomain.com/g" /etc/nginx/sites-available/dream-vacations.conf
sudo ln -s /etc/nginx/sites-available/dream-vacations.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo mkdir -p /var/www/certbot
sudo nginx -t && sudo systemctl reload nginx
```

Verify: `http://yourdomain.com` should now show the app.

## 5. Enable HTTPS with Let's Encrypt (Certbot)

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com \
  --non-interactive --agree-tos -m you@example.com --redirect
```

### Automatic renewal

```bash
systemctl list-timers | grep certbot
sudo certbot renew --dry-run
```

## 6. Backups and log rotation on the host

```bash
sudo ./scripts/rotate-logs.sh
sudo ./scripts/install-cron.sh
```

Schedules nightly `pg_dump` backups (`scripts/backup-db.sh`) to
`/var/backups/dream-vacations` (7-day retention) and weekly logrotate.

## 7. Verify end-to-end

```bash
curl -I https://yourdomain.com
curl https://yourdomain.com/api/health
```

## Redeploying after changes

- **CI/CD**: merge to `main` → GitHub Actions builds/pushes images to GHCR →
  (if the `ENABLE_DEPLOY` repo variable is `true` and SSH secrets are set)
  pulls and restarts on the EC2 host automatically.
- **Manual**: `./scripts/deploy.sh ubuntu@<elastic-ip>` from your local
  machine rsyncs the repo and rebuilds remotely.

## Tearing down

```bash
cd terraform
terraform destroy
```

This does not delete the S3 state bucket/DynamoDB table or the domain
registration itself - those were created outside Terraform.

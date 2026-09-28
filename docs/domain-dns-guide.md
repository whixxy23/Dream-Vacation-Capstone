# Domain & DNS Setup (Route 53)

## A note on "free domains"

Freenom (the long-time source of free `.tk`/`.ml`/`.ga`/`.cf`/`.gq` domains) was sued for
cybersquatting/phishing abuse, lost its ICANN registrar accreditation in late 2023, and
exited the domain business in 2024 - roughly 12.6 million of its domains stopped
resolving. It briefly resurfaced in 2026 but as a **paid** registrar, not a free one.
Treat any site still advertising "free `.tk`/`.ga`/`.cf` domains" as unreliable at best.

For a project you intend to actually demo and keep live, use one of these instead:

1. **Cheapest real TLD (recommended for this capstone)** - registrars like
   Namecheap, Cloudflare Registrar, or **Route 53 domain registration** sell
   `.click`, `.link`, `.xyz`, or similar TLDs for roughly $2-12/year. This is
   the only option that gives you a domain you fully own, with no risk of it
   being clawed back.
2. **Free subdomains from legitimate providers** - e.g. `eu.org` (apply for a
   free second-level domain), DuckDNS, or a subdomain under `is-a.dev` for
   dev/portfolio projects. Fine for a demo, not something you'd put on a
   resume as "my own domain."
3. **Route 53 registers domains directly** - if you go this route, skip a
   third-party registrar entirely: `aws route53domains register-domain ...`
   or via the console (Route 53 → Registered domains). Route 53 then
   auto-creates the hosted zone for you.

The rest of this guide assumes you registered a domain with any registrar and
want Route 53 to manage its DNS (this is what `terraform/route53.tf` sets up).

## 1. Create the hosted zone

Already automated by Terraform (`aws_route53_zone.primary` in `route53.tf`) when
you set `domain_name` in `terraform.tfvars`. To do it manually instead:

```bash
aws route53 create-hosted-zone \
  --name yourdomain.com \
  --caller-reference "$(date +%s)"
```

## 2. Point your registrar at Route 53's name servers

After `terraform apply`, get the name servers:

```bash
terraform output route53_name_servers
```

Log into whatever registrar you bought the domain from (Namecheap, Route 53
domain registration, etc.) and replace its default name servers with the four
`aws_route53_zone` name servers shown above. If you registered directly
through Route 53 domain registration, this step is automatic.

DNS propagation can take a few minutes to 48 hours; check with:

```bash
dig NS yourdomain.com +short
```

## 3. Create the A record to your EC2 instance

Also automated by Terraform (`aws_route53_record.app_a`), pointing at the
Elastic IP output by `terraform output instance_public_ip`. To do it manually:

```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id <ZONE_ID> \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "yourdomain.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "<ELASTIC_IP>"}]
      }
    }]
  }'
```

## 4. Verify

```bash
dig A yourdomain.com +short   # should return your EC2 Elastic IP
curl -I http://yourdomain.com # should get a response once Nginx is configured
```

Once this resolves, continue to `docs/deployment-guide.md` for the Nginx + Certbot
(SSL) steps.

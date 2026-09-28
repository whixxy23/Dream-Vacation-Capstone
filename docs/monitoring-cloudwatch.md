# Stretch Goal: Monitoring & Logging with CloudWatch

## 1. Ship container logs to CloudWatch Logs

Install the CloudWatch agent on the EC2 host:

```bash
sudo apt-get install -y amazon-cloudwatch-agent
```

Minimal config (`/opt/aws/amazon-cloudwatch-agent/etc/config.json`) to collect
Docker container logs and Nginx access/error logs:

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/dream-vacations-access.log",
            "log_group_name": "/dream-vacations/nginx/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/dream-vacations-error.log",
            "log_group_name": "/dream-vacations/nginx/error",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/dream-vacations/backup.log",
            "log_group_name": "/dream-vacations/backup",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "mem": { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["used_percent"], "resources": ["/"] }
    }
  }
}
```

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json -s
```

This requires the EC2 instance to have an IAM role with the
`CloudWatchAgentServerPolicy` attached - add this as an
`aws_iam_instance_profile` in Terraform if you extend `terraform/ec2.tf`.

## 2. Alarms

Example: alarm if the instance's status check fails, or disk usage crosses
85%, notifying an SNS topic/email. This can be added as
`terraform/monitoring.tf` with `aws_cloudwatch_metric_alarm` and `aws_sns_topic`
resources once the base infrastructure above is working.

## 3. Application-level metrics (optional next step)

For deeper visibility, the Express backend could emit custom metrics (request
counts, latency, error rate) via the CloudWatch embedded metric format, or
export Prometheus-style metrics and run Grafana instead. Out of scope for this
capstone but a natural next step for a real production system.

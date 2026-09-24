#!/usr/bin/env bash
#
# rotate-logs.sh
# Installs a logrotate policy for Dream Vacations application logs and
# host-level Nginx logs, then immediately triggers a rotation check.
# Idempotent: re-running just rewrites the same config file.
#
# Usage: sudo ./scripts/rotate-logs.sh

set -euo pipefail

LOGROTATE_CONF="/etc/logrotate.d/dream-vacations"
APP_LOG_DIR="${APP_LOG_DIR:-/var/log/dream-vacations}"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root or with sudo: sudo $0" >&2
  exit 1
fi

mkdir -p "${APP_LOG_DIR}"

cat > "${LOGROTATE_CONF}" <<EOF
${APP_LOG_DIR}/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    sharedscripts
}

/var/log/nginx/dream-vacations-*.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 \$(cat /var/run/nginx.pid) 2>/dev/null || true
    endscript
}
EOF

echo "[rotate-logs] Installed logrotate policy at ${LOGROTATE_CONF}"
echo "[rotate-logs] Validating and running a dry-run rotation..."
logrotate -d "${LOGROTATE_CONF}"

echo "[rotate-logs] Forcing an immediate rotation pass..."
logrotate -f "${LOGROTATE_CONF}"

echo "[rotate-logs] Done. Rotation will now run automatically via cron.daily."

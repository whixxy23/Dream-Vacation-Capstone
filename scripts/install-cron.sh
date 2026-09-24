#!/usr/bin/env bash
#
# install-cron.sh
# Registers cron jobs for nightly DB backups and weekly log rotation.
# Idempotent: overwrites any previous Dream Vacations cron.d entry, so
# re-running never duplicates jobs.
#
# Usage: sudo ./scripts/install-cron.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRON_FILE="/etc/cron.d/dream-vacations"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root or with sudo: sudo $0" >&2
  exit 1
fi

cat > "${CRON_FILE}" <<EOF
# dream-vacations-managed
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Nightly database backup at 02:00
0 2 * * * root ${REPO_ROOT}/scripts/backup-db.sh >> /var/log/dream-vacations/backup-cron.log 2>&1

# Weekly log rotation check on Sundays at 03:00 (safety net alongside logrotate's own cron.daily)
0 3 * * 0 root ${REPO_ROOT}/scripts/rotate-logs.sh >> /var/log/dream-vacations/rotate-cron.log 2>&1
EOF

chmod 0644 "${CRON_FILE}"
echo "[install-cron] Installed cron schedule at ${CRON_FILE}"
echo "[install-cron] Done. cron.d entries take effect automatically (no service restart needed)."

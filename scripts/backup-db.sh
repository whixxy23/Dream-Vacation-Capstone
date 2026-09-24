#!/usr/bin/env bash
#
# backup-db.sh
# Dumps the Dream Vacations PostgreSQL database (via pg_dump against
# DATABASE_URL) to a timestamped, gzipped file and prunes backups older
# than RETENTION_DAYS. Designed to run inside a cron job on the host,
# against the `db` container.
#
# Usage: ./scripts/backup-db.sh
# Env overrides: BACKUP_DIR, RETENTION_DAYS, DB_CONTAINER

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "${REPO_ROOT}/.env" ]]; then
  # shellcheck disable=SC1091
  set -a; source "${REPO_ROOT}/.env"; set +a
fi

BACKUP_DIR="${BACKUP_DIR:-/var/backups/dream-vacations}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
DB_CONTAINER="${DB_CONTAINER:-dream-vacations-db}"
POSTGRES_DB="${POSTGRES_DB:-dream_vacations}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/${POSTGRES_DB}_${TIMESTAMP}.sql.gz"
LOG_FILE="${LOG_FILE:-/var/log/dream-vacations/backup.log}"

log() {
  local msg
  msg="$(date '+%Y-%m-%d %H:%M:%S') [backup-db] $1"
  echo "${msg}"
  mkdir -p "$(dirname "${LOG_FILE}")" 2>/dev/null || true
  echo "${msg}" >> "${LOG_FILE}" 2>/dev/null || true
}

mkdir -p "${BACKUP_DIR}"

if ! docker ps --format '{{.Names}}' | grep -qx "${DB_CONTAINER}"; then
  log "ERROR: container '${DB_CONTAINER}' is not running. Aborting backup."
  exit 1
fi

log "Starting backup of database '${POSTGRES_DB}' from container '${DB_CONTAINER}'..."

# pg_dump runs *inside* the db container against its own localhost, using the
# same credentials docker-compose gave it - no need to re-parse DATABASE_URL.
if docker exec "${DB_CONTAINER}" \
    pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" --no-owner --clean \
    | gzip > "${BACKUP_FILE}.tmp"; then
  mv "${BACKUP_FILE}.tmp" "${BACKUP_FILE}"
  log "Backup succeeded: ${BACKUP_FILE} ($(du -h "${BACKUP_FILE}" | cut -f1))"
else
  rm -f "${BACKUP_FILE}.tmp"
  log "ERROR: pg_dump failed."
  exit 1
fi

log "Pruning backups older than ${RETENTION_DAYS} day(s)..."
find "${BACKUP_DIR}" -name "${POSTGRES_DB}_*.sql.gz" -type f -mtime "+${RETENTION_DAYS}" -print -delete \
  | while read -r removed; do log "Removed old backup: ${removed}"; done

log "Backup job complete. $(find "${BACKUP_DIR}" -name "${POSTGRES_DB}_*.sql.gz" | wc -l) backup(s) retained."

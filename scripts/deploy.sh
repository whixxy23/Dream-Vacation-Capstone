#!/usr/bin/env bash
#
# deploy.sh
# Beginner deployment path: rsyncs the repo to a remote EC2 host over SSH,
# then rebuilds and restarts the Docker Compose stack there.
#
# Usage: ./scripts/deploy.sh <user@host> [remote-path]

set -euo pipefail

REMOTE="${1:?Usage: $0 <user@host> [remote-path]}"
REMOTE_PATH="${2:-/home/ubuntu/dream-vacations}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[deploy] Syncing repository to ${REMOTE}:${REMOTE_PATH} ..."
rsync -az --delete \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'frontend/build' \
  --exclude '.env' \
  "${REPO_ROOT}/" "${REMOTE}:${REMOTE_PATH}/"

echo "[deploy] Rebuilding and restarting containers on ${REMOTE} ..."
# shellcheck disable=SC2029
ssh "${REMOTE}" "cd '${REMOTE_PATH}' && \
  test -f .env || cp .env.example .env && \
  docker compose pull --ignore-pull-failures || true && \
  docker compose up -d --build && \
  docker compose ps"

echo "[deploy] Done. Check the app at http://<ec2-public-ip>:\${FRONTEND_PORT:-8080}"

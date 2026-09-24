#!/usr/bin/env bash
#
# setup-env.sh
# Installs and configures everything needed to run the Dream Vacations
# stack on a fresh Ubuntu 22.04/24.04 host (local VM or EC2 instance).
# Safe to re-run: every step checks current state before acting.
#
# Usage: sudo ./scripts/setup-env.sh

set -euo pipefail

log() { printf '\n[setup-env] %s\n' "$1"; }

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root or with sudo: sudo $0" >&2
  exit 1
fi

DOCKER_COMPOSE_VERSION="v2.29.2"
TARGET_USER="${SUDO_USER:-$(whoami)}"

log "Updating apt package index..."
apt-get update -y

log "Installing base packages (git, curl, unzip, ca-certificates)..."
apt-get install -y --no-install-recommends \
  git curl unzip ca-certificates gnupg lsb-release logrotate

# --- Docker Engine ---------------------------------------------------------
if command -v docker >/dev/null 2>&1; then
  log "Docker already installed ($(docker --version)), skipping install."
else
  log "Installing Docker Engine from the official Docker repository..."
  install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  ARCH="$(dpkg --print-architecture)"
  CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

if docker compose version >/dev/null 2>&1; then
  log "Docker Compose plugin available ($(docker compose version --short))."
else
  log "Installing standalone docker-compose ${DOCKER_COMPOSE_VERSION}..."
  curl -fsSL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

if id -nG "${TARGET_USER}" | grep -qw docker; then
  log "User '${TARGET_USER}' already in docker group."
else
  log "Adding '${TARGET_USER}' to docker group (log out/in to take effect)..."
  usermod -aG docker "${TARGET_USER}"
fi

if command -v node >/dev/null 2>&1 && [[ "$(node -v)" == v20* ]]; then
  log "Node.js 20 already installed ($(node -v)), skipping."
else
  log "Installing Node.js 20.x..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi

log "Ensuring backup and log directories exist..."
mkdir -p /var/backups/dream-vacations
mkdir -p /var/log/dream-vacations
chown "${TARGET_USER}:${TARGET_USER}" /var/backups/dream-vacations /var/log/dream-vacations

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "${REPO_ROOT}/.env" ]]; then
  log ".env already exists, leaving it untouched."
else
  log "Creating .env from .env.example (edit it before deploying to production)."
  cp "${REPO_ROOT}/.env.example" "${REPO_ROOT}/.env"
fi

log "Environment setup complete. Docker: $(docker --version 2>/dev/null || echo 'not found')"
log "Log out and back in (or run 'newgrp docker') for group changes to apply."

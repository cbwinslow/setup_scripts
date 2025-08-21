#!/usr/bin/env bash
set -e

# Install Docker and Docker Compose if missing
if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y docker.io
fi

if ! command -v docker-compose >/dev/null 2>&1; then
  sudo apt-get install -y docker-compose
fi

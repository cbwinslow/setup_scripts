#!/usr/bin/env bash
set -e

# Deploy Grafana Loki using Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required for Loki deployment" >&2
  exit 1
fi

docker run -d --name loki -p 3100:3100 grafana/loki:2.9.1

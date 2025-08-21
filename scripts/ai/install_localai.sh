#!/usr/bin/env bash
set -e

# Deploy LocalAI using Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required for LocalAI deployment" >&2
  exit 1
fi

docker run -d --name localai -p 8080:8080 quay.io/go-skynet/local-ai:latest

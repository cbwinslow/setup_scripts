#!/usr/bin/env bash
set -e

# Deploy OpenSearch using Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required for OpenSearch deployment" >&2
  exit 1
fi

docker run -d --name opensearch -p 9200:9200 -p 9600:9600 -e "discovery.type=single-node" opensearchproject/opensearch:2.12.0

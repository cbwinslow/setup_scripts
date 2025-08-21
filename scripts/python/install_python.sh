#!/usr/bin/env bash
set -e

# Install system Python and pip if missing
if ! command -v python3 >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y python3 python3-pip
fi

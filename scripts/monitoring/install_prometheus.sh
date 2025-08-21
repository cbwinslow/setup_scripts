#!/usr/bin/env bash
set -e

# Install Prometheus using apt repository
sudo apt-get update
sudo apt-get install -y prometheus
sudo systemctl enable --now prometheus

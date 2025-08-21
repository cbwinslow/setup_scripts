#!/usr/bin/env bash
set -e

# Install PostgreSQL using apt
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql

#!/usr/bin/env bash
set -e

# Install pgvector extension for PostgreSQL
sudo apt-get update
sudo apt-get install -y postgresql-15-pgvector || sudo apt-get install -y postgresql-14-pgvector
sudo systemctl restart postgresql
sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS vector;"

#!/usr/bin/env bash
set -e

# Install ClickHouse server and client
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates
sudo mkdir -p /etc/apt/keyrings
sudo wget -qO /etc/apt/keyrings/clickhouse.asc https://packages.clickhouse.com/keys/gpg
echo "deb [signed-by=/etc/apt/keyrings/clickhouse.asc] https://packages.clickhouse.com/deb stable main" | sudo tee /etc/apt/sources.list.d/clickhouse.list
sudo apt-get update
sudo apt-get install -y clickhouse-server clickhouse-client
sudo systemctl enable --now clickhouse-server

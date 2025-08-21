#!/usr/bin/env bash
set -e

# Install Supabase CLI via npm
sudo apt-get update
sudo apt-get install -y npm
sudo npm install -g supabase

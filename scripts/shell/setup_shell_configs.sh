#!/usr/bin/env bash
set -e

# Deploy shell configuration files
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CONFIG_ROOT="$SCRIPT_DIR/../../configs/shell"

cp "$CONFIG_ROOT/bashrc" "$HOME/.bashrc"
cp "$CONFIG_ROOT/zshrc" "$HOME/.zshrc"

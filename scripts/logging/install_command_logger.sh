#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo install -m 0755 "$SCRIPT_DIR/command_logger.sh" /usr/local/bin/command_logger.sh
sudo cp "$SCRIPT_DIR/../../systemd/command-logger.service" /etc/systemd/system/command-logger.service
sudo systemctl daemon-reload
sudo systemctl enable --now command-logger.service

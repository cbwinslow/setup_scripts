#!/usr/bin/env bash
set -e

LOG_FILE=/var/log/command_logger.log
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Tail shell histories and append to log file
(tail -F "$HOME/.bash_history" "$HOME/.zsh_history" 2>/dev/null >> "$LOG_FILE") &

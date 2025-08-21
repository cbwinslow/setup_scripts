#!/usr/bin/env bash
set -e

cat <<'CFG' > ~/.tmux.conf
# Enable mouse mode
set -g mouse on

# Use Ctrl+a as prefix instead of Ctrl+b
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix
CFG

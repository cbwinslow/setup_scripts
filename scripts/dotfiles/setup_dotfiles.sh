#!/usr/bin/env bash
set -e

# Install chezmoi and apply dotfiles repository
if ! command -v chezmoi >/dev/null 2>&1; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
fi

chezmoi init https://github.com/example/dotfiles.git
chezmoi apply

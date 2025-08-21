#!/usr/bin/env bash
set -e

# Install pyenv for managing Python versions
if ! command -v pyenv >/dev/null 2>&1; then
  curl https://pyenv.run | bash
fi

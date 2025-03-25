#!/usr/bin/env bash
###############################################################################
# Script Name: nextcloud_docker_setup.sh
# Author: ChatGPT
# Description:
#   This script automates the deployment of a Nextcloud instance in a Docker
#   container, primarily designed for a Proxmox environment (though it will
#   work on most Debian/Ubuntu-like hosts).
#
#   - Variables are defined at the top for easy customization.
#   - Advanced error handling (traps and validations).
#   - Minimal user interaction required; most decisions are scripted.
#
# Usage:
#   1. Make it executable: chmod +x nextcloud_docker_setup.sh
#   2. Run as root or use sudo: ./nextcloud_docker_setup.sh
#
# Notes:
#   - If Docker is absent and AUTO_INSTALL_DOCKER=true, the script attempts
#     to install Docker automatically. If set to false, the script will exit
#     if Docker is not found.
#   - Adjust volumes, image tags, and container ports as needed.
###############################################################################

###############################################################################
#                          VARIABLE DECLARATIONS
###############################################################################
# Name of the Docker container.
CONTAINER_NAME="nextcloud_container"

# Docker image to use for Nextcloud.
NEXTCLOUD_DOCKER_IMAGE="nextcloud:latest"

# Host port on which Nextcloud will be exposed (HTTP).
NEXTCLOUD_EXPOSED_PORT="8080"

# Directory on the host that will contain Nextcloud data.
# For example, "/srv/nextcloud_data" or "/var/lib/nextcloud_data".
# Make sure you have adequate permissions and space.
NEXTCLOUD_DATA_DIR="/srv/nextcloud_data"

# Nextcloud admin username. For a production environment, choose something secure.
NEXTCLOUD_ADMIN_USER="admin"

# Nextcloud admin password. For production, definitely change this to something safe.
NEXTCLOUD_ADMIN_PASSWORD="changeme123"

# (Optional) Install Docker if not found. If false, the script will exit if Docker is missing.
AUTO_INSTALL_DOCKER=true

# Debian/Ubuntu Docker dependencies (adjust if you have alternative repositories).
DOCKER_DEPENDENCIES=("apt-transport-https" "ca-certificates" "curl" "gnupg" "lsb-release")

# If you want to redirect logs, you can specify a log file path (e.g. /var/log/nextcloud_setup.log).
LOG_FILE="/var/log/nextcloud_setup.log"

###############################################################################
#                          ERROR HANDLING & TRAPS
###############################################################################
# Enable strict bash error settings:
# -E  : Functions inherit trap on ERR
# -u  : Treat unset variables as an error
# -o pipefail : Any failed command in a pipeline causes the pipeline to fail
set -Euo pipefail

# Trap function to handle errors
error_handler() {
  local exit_code=$?
  echo "[ERROR] Script encountered an unexpected error on line $1. Exit code: $exit_code"
  echo "Check logs and previous output for clues. Exiting."
  exit "$exit_code"
}

# Trap function to handle script exit (any exit, successful or not).
cleanup_handler() {
  local exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    echo "[INFO] Script completed successfully."
  else
    echo "[INFO] Script exited with error code: $exit_code"
  fi
}

# BASH_SOURCE[0] is the current file, so we trap the line number where the error occurred
trap 'error_handler $LINENO' ERR
trap cleanup_handler EXIT

###############################################################################
#                          UTILITY FUNCTIONS
###############################################################################
log() {
  # Log to stdout and optionally to a file
  local message="$1"
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $message"
  if [[ -n "$LOG_FILE" ]]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') : $message" >> "$LOG_FILE"
  fi
}

check_command_exists() {
  # Check if a command is available on PATH.
  # Usage: check_command_exists <command>
  command -v "$1" &>/dev/null
}

install_docker_if_missing() {
  # If Docker is not found, optionally install it.
  if ! check_command_exists "docker"; then
    if [[ "$AUTO_INSTALL_DOCKER" == "true" ]]; then
      log "[INFO] Docker not found. Installing Docker..."

      # Install using official Docker repository for Debian/Ubuntu
      # Adjust if you have your own Docker registry or custom steps.
      apt-get update -y
      apt-get install -y "${DOCKER_DEPENDENCIES[@]}"
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

      # Add Docker stable repo
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list >/dev/null

      apt-get update -y
      apt-get install -y docker-ce docker-ce-cli containerd.io

      # Enable and start Docker
      systemctl enable docker
      systemctl start docker

      log "[INFO] Docker installation completed."
    else
      log "[ERROR] Docker is not installed and AUTO_INSTALL_DOCKER=false. Exiting."
      exit 1
    fi
  else
    log "[INFO] Docker is already installed."
  fi
}

validate_host_environment() {
  # Check if script is run as root
  if [[ $EUID -ne 0 ]]; then
    log "[ERROR] Please run this script as root or with sudo."
    exit 1
  fi
}

validate_port_availability() {
  # Check if desired port is already in use
  if ss -tulpn | grep -q ":${NEXTCLOUD_EXPOSED_PORT} "; then
    log "[ERROR] Port ${NEXTCLOUD_EXPOSED_PORT} is already in use. Choose a different port."
    exit 1
  fi
}

create_data_directory() {
  # Validate or create Nextcloud data directory
  if [[ -d "$NEXTCLOUD_DATA_DIR" ]]; then
    log "[INFO] Nextcloud data directory $NEXTCLOUD_DATA_DIR already exists."
  else
    log "[INFO] Creating Nextcloud data directory $NEXTCLOUD_DATA_DIR"
    mkdir -p "$NEXTCLOUD_DATA_DIR"
    if [[ ! -d "$NEXTCLOUD_DATA_DIR" ]]; then
      log "[ERROR] Failed to create data directory $NEXTCLOUD_DATA_DIR."
      exit 1
    fi
  fi
}

pull_docker_image() {
  # Pull the Nextcloud Docker image
  log "[INFO] Pulling Docker image: $NEXTCLOUD_DOCKER_IMAGE"
  docker pull "$NEXTCLOUD_DOCKER_IMAGE"
}

run_nextcloud_container() {
  # Create or run Nextcloud container
  log "[INFO] Running Nextcloud container with name: $CONTAINER_NAME"
  # Remove any existing container with the same name to avoid conflict
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
    log "[INFO] A container named $CONTAINER_NAME already exists. Stopping and removing it..."
    docker stop "$CONTAINER_NAME" || true
    docker rm "$CONTAINER_NAME" || true
  fi

  # Run the container
  docker run -d \
    --name "$CONTAINER_NAME" \
    -p "${NEXTCLOUD_EXPOSED_PORT}:80" \
    -e NEXTCLOUD_ADMIN_USER="$NEXTCLOUD_ADMIN_USER" \
    -e NEXTCLOUD_ADMIN_PASSWORD="$NEXTCLOUD_ADMIN_PASSWORD" \
    -v "${NEXTCLOUD_DATA_DIR}:/var/www/html" \
    "$NEXTCLOUD_DOCKER_IMAGE"

  # Validate if container started successfully
  if [[ $(docker ps --format '{{.Names}}' | grep "^${CONTAINER_NAME}\$") == "$CONTAINER_NAME" ]]; then
    log "[INFO] Nextcloud container '$CONTAINER_NAME' is running."
  else
    log "[ERROR] Nextcloud container failed to start."
    exit 1
  fi
}

###############################################################################
#                            MAIN EXECUTION FLOW
###############################################################################
main() {
  log "[INFO] Starting Nextcloud Docker Setup Script..."

  # 1. Validate host environment
  validate_host_environment

  # 2. Install Docker if missing
  install_docker_if_missing

  # 3. Validate that Docker is operational
  if ! check_command_exists "docker"; then
    log "[ERROR] Docker command not found after installation. Exiting."
    exit 1
  fi

  # 4. Validate port availability
  validate_port_availability

  # 5. Validate or create data directory
  create_data_directory

  # 6. Pull the Nextcloud image
  pull_docker_image

  # 7. Run the Nextcloud container
  run_nextcloud_container

  log "[INFO] Nextcloud Docker Setup Script completed."
  log "[INFO] Access Nextcloud via http://<Your-Host-IP>:${NEXTCLOUD_EXPOSED_PORT}"
}

# Execute the main function
main

#!/bin/bash

# Enhanced Red Hat Post-Installation Setup Script
# Installs development tools, common applications, AI tools, Docker images,
# configures basic terminal enhancements, theming elements, and handles config backup/restore.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting enhanced post-installation setup for Red Hat based system..."
echo "Please ensure you are running this script with sudo or as root."
echo "NOTE: This script requires user interaction for confirmations and choices."
echo "      Manual steps will be required after script completion (see comments)."
sleep 3 # Give user time to read

# --- Configuration Variables (Customize these!) ---

# List of essential Python packages you want to install GLOBALLY (use venvs for projects)
PYTHON_PACKAGES=(
    "requests"
    "numpy"
    "pandas"
    "scipy"
    "matplotlib"
    "jupyterlab"
    "virtualenv"
    "pipenv"
    "flask"
    "django"
    "openai"             # OpenAI API client
    "google-generativeai" # Gemini API client
    # Add more general-purpose packages here
)

# Location for backing up/restoring configuration files
CONFIG_BACKUP_LOCATION="/path/to/your/config/backup/location" # !!! CHANGE THIS !!!

# List of configuration files and directories to backup/restore
CONFIG_FILES_TO_MANAGE=(
    ".bashrc"
    ".zshrc"          # Add Zsh config file
    ".gitconfig"
    ".config"         # Be careful, this can be large! Consider specific subdirs like .config/kitty, .config/htop
    ".ssh"            # IMPORTANT: Handle SSH keys with care and proper permissions
    ".local/share/fonts" # User-installed fonts
    ".local/share/atuin" # Atuin history database (optional)
    ".mozilla/firefox" # Firefox profiles (bookmarks, history - RESTORE WITH CAUTION, extensions need manual reinstall)
    # Add more files/directories here
)

# Directory to download AppImages and other installers
DOWNLOAD_DIR="$HOME/Downloads/installers"
# Directory for Python Virtual Environments for Agent Development
PYTHON_DEV_VENVS_DIR="$HOME/dev/python_venvs" # Using ~/dev, NOT /dev

# --- Helper Functions ---

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to add a repo if it doesn't exist
add_repo() {
    local repo_url=$1
    local repo_name=$(basename "$repo_url" .repo)
    local repo_path="/etc/yum.repos.d/${repo_name}.repo"

    if [ ! -f "$repo_path" ]; then
        echo "Adding repository: $repo_name"
        sudo dnf config-manager --add-repo "$repo_url"
    else
        echo "Repository $repo_name already exists."
    fi
}

# --- Prerequisite Setup ---

echo "Creating download directory: $DOWNLOAD_DIR"
mkdir -p "$DOWNLOAD_DIR"
echo "Creating Python development venv directory: $PYTHON_DEV_VENVS_DIR"
mkdir -p "$PYTHON_DEV_VENVS_DIR"
echo "Note: Python virtual environments for projects should be created inside $PYTHON_DEV_VENVS_DIR manually."

# --- System Update and EPEL Repo ---
install_base_system() {
    echo "Updating system packages..."
    sudo dnf update -y
    echo "System update complete."

    echo "Checking and installing EPEL repository..."
    if ! dnf repolist | grep -q "epel"; then
        sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm
        # Check for CodeReady Builder (CRB) repo, needed by EPEL on RHEL 8/9
        if rpm -E %rhel | grep -qE '8|9'; then
             echo "Enabling CRB repository for RHEL $(rpm -E %rhel)..."
             sudo dnf config-manager --set-enabled crb || echo "CRB repo enabling failed, EPEL might have issues."
        fi
        echo "EPEL repository installed."
    else
        echo "EPEL repository seems to be already enabled."
    fi
    # Update again to include EPEL packages
    echo "Updating package list with EPEL..."
    sudo dnf update -y
    echo "Base system setup complete."
}

# --- Install Development Tools ---
install_dev_tools() {
    echo "Installing Development Tools group..."
    sudo dnf groupinstall -y "Development Tools"
    echo "Installing other useful utilities (htop, tree, curl, wget, vim, jq)..."
    sudo dnf install -y htop tree curl wget vim jq unzip git-lfs
    git lfs install --system # Initialize git-lfs system-wide
    echo "Development tools installed."
}

# --- Install Node.js and npm ---
install_node() {
    echo "Installing Node.js and npm..."
    sudo dnf install -y nodejs npm
    echo "Node.js and npm installed. Version:"
    node --version || echo "Node not found."
    npm --version || echo "npm not found."
}

# --- Install Python & Global Packages ---
install_python() {
    echo "Installing Python 3, pip, and devel packages..."
    sudo dnf install -y python3 python3-pip python3-devel
    echo "Python 3 installed."
    echo "Upgrading pip..."
    sudo python3 -m pip install --upgrade pip
    echo "Installing specified GLOBAL Python packages using pip..."
    if [ ${#PYTHON_PACKAGES[@]} -gt 0 ]; then
        sudo python3 -m pip install "${PYTHON_PACKAGES[@]}"
        echo "Global Python packages installed: ${PYTHON_PACKAGES[*]}"
    else
        echo "No global Python packages specified in PYTHON_PACKAGES array."
    fi
}

# --- Setup Python Agent Development Environment ---
setup_python_dev_env() {
    echo "--- Python Agent Development Setup ---"
    echo "Directory created: $PYTHON_DEV_VENVS_DIR"
    echo "To create a new project environment (example):"
    echo "1. cd $PYTHON_DEV_VENVS_DIR"
    echo "2. python3 -m venv my_agent_project_env"
    echo "3. source my_agent_project_env/bin/activate"
    echo "4. pip install --upgrade pip"
    echo "5. pip install openllm openrouter-api pydantic langchain langsmith langgraph crewai autogpt mistralai openai # Add/remove as needed"
    echo "6. # ... work on your project ..."
    echo "7. deactivate"
    echo "--- End Python Agent Development Setup ---"
}


# --- Install Configuration Management Tools ---
install_config_tools() {
    echo "Installing configuration management tools..."
    echo "Installing Ansible..."
    sudo dnf install -y ansible-core

    echo "Installing Terraform..."
    add_repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    sudo dnf install -y terraform

    echo "Installing Puppet Agent..."
    local rhel_ver=$(rpm -E %rhel)
    local puppet_repo_url="https://yum.puppet.com/puppet$(rpm -E '%{?puppet_repo_version:-7}')-release-el-${rhel_ver}.noarch.rpm"
    if curl --output /dev/null --silent --head --fail "$puppet_repo_url"; then
        sudo rpm -Uvh "$puppet_repo_url"
        sudo dnf install -y puppet-agent
    else
        echo "Warning: Could not find Puppet repo RPM for RHEL $rhel_ver. Skipping Puppet installation."
    fi

    echo "Configuration management tools installation attempted."
}

# --- Install Containerization Tools ---
install_docker() {
    echo "Installing Docker..."
    if ! command_exists docker; then
        add_repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        echo "Starting and enabling Docker service..."
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "Adding current user ($USER) to the docker group..."
        sudo usermod -aG docker $USER || echo "Failed to add user to docker group. Manual step needed?"
        echo "Docker installed. You may need to log out and back in for group changes to take effect."
    else
        echo "Docker appears to be already installed."
    fi
}

# --- Pull Common Docker Images ---
pull_docker_images() {
    echo "--- Pulling Docker Images ---"
    if ! command_exists docker; then
        echo "Docker command not found. Skipping Docker image pulls. Was Docker installed correctly?"
        return 1
    fi

    echo "Pulling requested Docker images... This may take some time."
    # Ensure user is in docker group or running script with sudo that has docker access
    # May need to run `newgrp docker` in the shell or log out/in first if just added.
    # Running pull commands with sudo to be safe if group change hasn't propagated.

    sudo docker pull ghcr.io/gethomepage/homepage:latest || echo "Failed to pull homepage"
    sudo docker pull cloudflare/cloudflared:latest || echo "Failed to pull cloudflared"
    sudo docker pull nginx:latest || echo "Failed to pull nginx"
    sudo docker pull traefik:latest || echo "Failed to pull traefik" # Reverse Proxy / Edge Router
    sudo docker pull nextcloud:latest || echo "Failed to pull nextcloud"
    sudo docker pull matrixdotorg/synapse:latest || echo "Failed to pull synapse" # Matrix Chat Server
    sudo docker pull prom/prometheus:latest || echo "Failed to pull prometheus"
    sudo docker pull grafana/grafana:latest || echo "Failed to pull grafana"

    echo "Docker image pulls attempted."
    echo "NOTE: Images are downloaded, but NOT running."
    echo "You need to manually run these containers using 'docker run' or 'docker-compose'."
    echo "Refer to the official documentation for each image for configuration and run commands."
    echo "Examples:"
    echo "- Homepage: https://gethomepage.dev/latest/installation/docker/"
    echo "- Cloudflared: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/"
    echo "- Traefik: https://doc.traefik.io/traefik/getting-started/quick-start/"
    echo "- Nextcloud: https://github.com/nextcloud/docker"
    echo "- Synapse: https://matrix-org.github.io/synapse/latest/setup/installation.html"
    echo "- Prometheus: https://prometheus.io/docs/prometheus/latest/installation/#docker"
    echo "- Grafana: https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/"
    echo "--- End Docker Image Pulls ---"
}


# --- Install Common Applications ---
install_apps() {
    echo "Installing common applications..."

    echo "Installing VS Code..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update
    sudo dnf install -y code

    echo "Installing Warp Terminal..."
    sudo rpm --import https://pkg.cloudflareclient.com/cloudflare-warp-public.gpg
    curl -fsSL https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo > /dev/null
    sudo dnf update -y
    sudo dnf install -y warp-terminal || echo "Warp installation failed. Check repo or manual download."

    echo "Installing Windscribe CLI..."
    add_repo https://repo.windscribe.com/repo/centos/windscribe.repo
    sudo dnf install -y windscribe-cli || echo "Windscribe installation failed. Check repo or manual download."

    echo "Installing Bitwarden CLI (via npm)..."
    if command_exists npm; then
        sudo npm install -g @bitwarden/cli
    else
        echo "Warning: npm not found. Skipping Bitwarden CLI installation."
    fi

    echo "Installing Java (needed for some tools like Minecraft servers)..."
    sudo dnf install -y java-latest-openjdk

    echo "Common applications installation attempted."
}

# --- Install System Admin Tools ---
install_admin_tools() {
    echo "Installing system administration tools..."
    echo "Installing Cockpit (Web Admin Interface)..."
    sudo dnf install -y cockpit
    echo "Enabling and starting Cockpit socket..."
    sudo systemctl enable --now cockpit.socket
    echo "Cockpit installed. Access it at https://<your-server-ip>:9090"
    # Note: Firewall might need adjustment for port 9090
    if command_exists firewall-cmd; then
        echo "Attempting to open port 9090 in firewalld for Cockpit..."
        sudo firewall-cmd --add-service=cockpit --permanent
        sudo firewall-cmd --reload
    fi
    echo "Admin tools installation attempted."
}


# --- Install AI and LLM Tools ---
install_ai_tools() {
    echo "Installing AI/LLM Tools..."

    echo "Downloading Cursor AppImage..."
    CURSOR_URL="https://download.cursor.sh/linux/appImage/latest"
    wget "$CURSOR_URL" -O "$DOWNLOAD_DIR/Cursor.AppImage" || echo "Failed to download Cursor."
    chmod +x "$DOWNLOAD_DIR/Cursor.AppImage"
    echo "Cursor AppImage downloaded to $DOWNLOAD_DIR. Run manually or use AppImageLauncher."

    echo "Installing Ollama..."
    if ! command_exists ollama; then
        curl -fsSL https://ollama.com/install.sh | sh
    else
        echo "Ollama appears to be already installed."
    fi

    echo "Downloading LM Studio AppImage..."
    # !!! LM Studio URL might change - check https://lmstudio.ai/ !!!
    LMSTUDIO_URL="https://s3.amazonaws.com/releases.lmstudio.ai/linux/main/LM-Studio-0.2.20-linux-x86_64.AppImage" # Example URL - VERIFY
    wget "$LMSTUDIO_URL" -O "$DOWNLOAD_DIR/LM_Studio.AppImage" || echo "Failed to download LM Studio. Check URL."
    chmod +x "$DOWNLOAD_DIR/LM_Studio.AppImage"
    echo "LM Studio AppImage downloaded to $DOWNLOAD_DIR. Run manually or use AppImageLauncher."

    echo "Installing AnythingLLM prerequisites (Docker)..."
    install_docker # Ensure Docker is installed
    echo "For AnythingLLM, follow their Docker setup guide after this script finishes."
    echo "See: https://docs.useanything.com/getting-started/installation-options/docker"

    echo "AI/LLM tools installation attempted."
}

# --- Setup Enhanced Terminal (Zsh, Oh My Zsh, Atuin) ---
setup_terminal() {
    echo "Setting up enhanced terminal environment..."

    echo "Installing Zsh..."
    sudo dnf install -y zsh

    echo "Installing Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || echo "Oh My Zsh installation failed."
        echo "Oh My Zsh installed. Configuration file: ~/.zshrc"
    else
        echo "Oh My Zsh already installed."
    fi

    echo "Installing Atuin (Shell History Sync & Search)..."
    if ! command_exists atuin; then
         bash <(curl https://raw.githubusercontent.com/atuinsh/atuin/main/install.sh)
         echo "Atuin installed. Add 'eval \"\$(atuin init zsh)\"' to your ~/.zshrc manually."
    else
        echo "Atuin appears to be already installed."
    fi

    echo "Enhanced terminal setup complete."
    echo "IMPORTANT: To use Zsh as your default shell, run 'chsh -s $(which zsh)' manually and log out/in."
    echo "           Configure ~/.zshrc for themes, plugins, and Atuin ('eval \"\$(atuin init zsh)\"')."
}

# --- Apply Theming (Matrix/Hacker Style) ---
apply_theming() {
    echo "--- Applying Theming Elements (Matrix/Hacker Style) ---"

    echo "Installing themeable terminal (Kitty)..."
    sudo dnf install -y kitty || echo "Kitty installation failed."

    echo "Installing useful fonts (JetBrains Mono, Fira Code, Noto)..."
    sudo dnf install -y 'jetbrains-mono-fonts-all' 'fira-code-fonts' 'google-noto-sans-mono-fonts' || echo "Font installation failed."
    # Consider Meslo Nerd Font (often used with P10k) - Manual install usually needed
    # echo "Consider installing MesloLGS NF manually for Powerlevel10k: https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k"

    echo "Downloading sample Matrix theme for Kitty..."
    mkdir -p "$HOME/.config/kitty/themes"
    curl -fsSL "https://raw.githubusercontent.com/dexpota/kitty-themes/master/themes/Matrix.conf" \
         -o "$HOME/.config/kitty/themes/Matrix.conf" || echo "Failed to download Kitty Matrix theme."
    echo "Sample Kitty theme downloaded to ~/.config/kitty/themes/Matrix.conf"
    echo "To use: Edit ~/.config/kitty/kitty.conf and add 'include ./themes/Matrix.conf'"

    echo "Installing VS Code Matrix themes..."
    if command_exists code; then
        # Install a couple of popular options, user can choose in VS Code
        code --install-extension esot.theme-matrix || echo "Failed to install VS Code theme esot.theme-matrix"
        code --install-extension samuelcolvin.mono-dark-pro || echo "Failed to install VS Code theme samuelcolvin.mono-dark-pro (similar vibe)"
        echo "VS Code themes installed. Select one within VS Code (Ctrl+K Ctrl+T)."
    else
        echo "VS Code command not found, skipping theme installation."
    fi

    echo "Installing GNOME Tweaks (for GNOME desktop theme management)..."
    sudo dnf install -y gnome-tweaks || echo "Failed to install gnome-tweaks. Not a GNOME desktop?"

    echo "Theming elements installed/downloaded."
    echo "Manual Steps Recommended:"
    echo "- Configure Kitty: Edit ~/.config/kitty/kitty.conf (apply theme, set font 'Fira Code' or 'JetBrains Mono NL')."
    echo "- Configure Zsh/Oh My Zsh: Explore themes (e.g., Powerlevel10k via 'p10k configure'), set fonts in terminal."
    echo "- Configure Warp: Explore Warp's built-in themes or create custom ones."
    echo "- Desktop Theme: Use GNOME Tweaks (or KDE System Settings) to find/apply GTK/Shell themes from sites like gnome-look.org."
    echo "--- End Theming ---"
}


# --- API Key Management Guidance ---
manage_api_keys() {
    echo ""
    echo "--- API Key Management ---"
    echo "IMPORTANT: Never store API keys directly in scripts or commit them to version control."
    echo "Recommended methods: Use a password manager (Bitwarden), environment variables in a secure file (~/.env, add to .gitignore), or secrets management tools."
    echo "Adding placeholder API key exports to ~/.bashrc and ~/.zshrc..."
    echo "You MUST edit these files and replace placeholders securely."

    local bashrc_file="$HOME/.bashrc"
    local zshrc_file="$HOME/.zshrc"
    local api_keys_comment="# Placeholder API Keys (Replace with real keys or load securely!)"
    local api_keys_exports=(
        "export OPENAI_API_KEY=\"YOUR_OPENAI_KEY_HERE\""
        "export GEMINI_API_KEY=\"YOUR_GEMINI_KEY_HERE\""
        "export MISTRAL_API_KEY=\"YOUR_MISTRAL_KEY_HERE\""
        "export LANGSMITH_API_KEY=\"YOUR_LANGSMITH_KEY_HERE\""
        # Add other keys as needed
        # "export HUGGINGFACE_TOKEN=\"YOUR_HF_TOKEN_HERE\""
        # "export OPENROUTER_API_KEY=\"YOUR_OPENROUTER_KEY_HERE\""
    )

    # Add to .bashrc
    if [ -f "$bashrc_file" ]; then
        if ! grep -qF "$api_keys_comment" "$bashrc_file"; then
            echo -e "\n$api_keys_comment" >> "$bashrc_file"
            for key_export in "${api_keys_exports[@]}"; do
                echo "$key_export" >> "$bashrc_file"
            done
            echo "Placeholders added to $bashrc_file."
        fi
    fi

    # Add to .zshrc (if it exists)
    if [ -f "$zshrc_file" ]; then
         if ! grep -qF "$api_keys_comment" "$zshrc_file"; then
            echo -e "\n$api_keys_comment" >> "$zshrc_file"
            for key_export in "${api_keys_exports[@]}"; do
                echo "$key_export" >> "$zshrc_file"
            done
            echo "Placeholders added to $zshrc_file."
        fi
    else
         echo "Warning: ~/.zshrc not found. Skipping API key placeholders for Zsh."
    fi

     echo "Remember to source the file (e.g., 'source ~/.bashrc') or restart your shell after editing."
     echo "--- End API Key Management ---"
}


# --- Configuration File Management ---

# Function to backup configuration files
backup_configs() {
    echo "Backing up configuration files..."
    if [ ! -d "$CONFIG_BACKUP_LOCATION" ]; then
        echo "Creating backup directory: $CONFIG_BACKUP_LOCATION"
        mkdir -p "$CONFIG_BACKUP_LOCATION"
    fi

    echo "Copying files to $CONFIG_BACKUP_LOCATION"
    # Ensure rsync is installed
    if ! command_exists rsync; then sudo dnf install -y rsync; fi

    for item in "${CONFIG_FILES_TO_MANAGE[@]}"; do
        source_path="$HOME/$item"
        if [ -e "$source_path" ]; then
            echo "Backing up $item..."
            rsync -aR "$source_path" "$CONFIG_BACKUP_LOCATION/"
        else
            echo "Warning: $source_path does not exist, skipping backup."
        fi
    done
    echo "Configuration file backup complete."
    echo "Strongly consider using Git to manage your dotfiles for better version control."
}

# Function to restore configuration files
restore_configs() {
    echo "Restoring configuration files..."
    if [ ! -d "$CONFIG_BACKUP_LOCATION" ]; then
        echo "Error: Backup location $CONFIG_BACKUP_LOCATION does not exist!"
        return 1
    fi

    echo "Copying files from $CONFIG_BACKUP_LOCATION to $HOME"
    # Ensure rsync is installed
    if ! command_exists rsync; then sudo dnf install -y rsync; fi

    rsync -av --exclude '.git/' "$CONFIG_BACKUP_LOCATION/" "$HOME/"

    # Special handling for .ssh directory permissions
    if [[ " ${CONFIG_FILES_TO_MANAGE[@]} " =~ " .ssh " ]] && [ -d "$HOME/.ssh" ]; then
        echo "Setting restrictive permissions for $HOME/.ssh directory..."
        chmod 700 "$HOME/.ssh"
        find "$HOME/.ssh" -type f -exec chmod 600 {} \;
        find "$HOME/.ssh" -name "*.pub" -exec chmod 644 {} \;
    fi

    echo "Configuration file restore complete."
    echo "IMPORTANT: Firefox profile restored, but extensions need MANUAL installation."
    echo "You may need to restart your shell or log out/in for all changes to take effect."
}

# --- Main Execution Logic ---

install_base_system
install_dev_tools
install_node
install_python
setup_python_dev_env # Setup directory and provide instructions
install_config_tools
install_docker       # Install docker daemon first
pull_docker_images   # Then pull images
install_apps
install_admin_tools
install_ai_tools     # Installs Ollama, downloads AppImages
setup_terminal       # Installs Zsh, Oh My Zsh, Atuin
apply_theming        # Installs fonts, Kitty, themes
manage_api_keys      # Add guidance and placeholders

# Ask the user whether to backup or restore configs
echo ""
echo "--- Configuration File Management ---"
echo "Your specified backup/restore location: $CONFIG_BACKUP_LOCATION"
echo "Files/Dirs to manage: ${CONFIG_FILES_TO_MANAGE[*]}"
echo "WARNING: Restoring Firefox profile (~/.mozilla/firefox) might overwrite existing data and requires manual extension reinstallation."
echo ""
echo "Do you want to backup existing configurations or restore from the location above?"
select choice in "Backup" "Restore" "Skip"; do
    case $choice in
        Backup )
            backup_configs
            break;;
        Restore )
            read -p "ARE YOU SURE you want to restore configs from $CONFIG_BACKUP_LOCATION? This will overwrite existing files in $HOME. (y/N): " confirm_restore
            if [[ "$confirm_restore" =~ ^[Yy]$ ]]; then
                restore_configs
            else
                echo "Restore cancelled."
            fi
            break;;
        Skip )
            echo "Skipping configuration file management."
            break;;
        * ) echo "Invalid choice. Please select 1, 2, or 3.";;
    esac
done


# --- Final Steps ---
echo ""
echo "-------------------------------------"
echo "Setup script finished!"
echo "-------------------------------------"
echo ""
echo "Please review the output above for any errors."
echo ""
echo "--- MANUAL ACTIONS REQUIRED ---"
echo "1.  **API Keys:** Edit ~/.bashrc or ~/.zshrc to add your real API keys securely."
echo "2.  **Change Shell:** Run 'chsh -s $(which zsh)' and log out/in to use Zsh."
echo "3.  **Zsh Configuration:** Customize ~/.zshrc (themes like Powerlevel10k 'p10k configure', plugins, add 'eval \"\$(atuin init zsh)\"')."
echo "4.  **Terminal Configuration (Kitty/Warp):** Edit config files (~/.config/kitty/kitty.conf or Warp settings) to set fonts (e.g., 'Fira Code', 'JetBrains Mono NL', 'MesloLGS NF') and apply themes (e.g., include downloaded Matrix theme for Kitty)."
echo "5.  **Firefox Extensions:** Manually install required extensions (e.g., Bitwarden) via Firefox Add-ons."
echo "6.  **AppImages:** Run downloaded AppImages ($DOWNLOAD_DIR) like './Cursor.AppImage'. Consider using 'appimaged' for menu integration."
echo "7.  **Docker Group:** Log out and log back in for Docker group permissions to apply fully."
echo "8.  **Docker Containers:** Manually run/configure pulled Docker images using 'docker run' or 'docker-compose' (Homepage, Nextcloud, Synapse, etc.)."
echo "9.  **AI Tools:** Configure Ollama ('ollama pull <model>'), LM Studio, AnythingLLM (Docker setup), etc."
echo "10. **Python Venvs:** Create virtual environments in $PYTHON_DEV_VENVS_DIR for your projects ('python3 -m venv env_name', 'source env_name/bin/activate', 'pip install ...')."
echo "11. **Cockpit Access:** Access Cockpit at https://<your-server-ip>:9090 (ensure firewall allows port 9090)."
echo "12. **Desktop Theming:** Use GNOME Tweaks or similar tools to apply system-wide themes if desired."
echo "13. **Review & Customize:** Adapt this script further for any missing tools or specific configurations."
echo ""
echo "Good luck with your new setup!"

exit 0

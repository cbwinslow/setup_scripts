
[Docker]
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo groupadd docker
sudo usermod -aG docker $USER

sudo systemctl enable docker.service
sudo systemctl enable containerd.service


# [NordVpn]
sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
sudo usermod -aG nordvpn $USER

# To install Samba and configure to use with Meshnet for 
sudo apt update && sudo apt install samba -y
sudo smbpasswd -a $USER
sudo usermod -aG sambashare $USER
sudo apt install nautilus-share -y
nautilus -q

# [Linux CIFS]
sudo apt update && sudo apt install cifs-utils -y

# See NordVPN documentation about accessing a shared mount point

# [SyncThing]
sudo curl -o /usr/share/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
sudo systemctl enable syncthing@$USER.service
sudo systemctl start syncthing@$USER.service

# [Vagrant]
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant

# [DevBox]
curl -fsSL https://get.jetify.com/devbox | bash

# [Tailscale]
curl -fsSL https://tailscale.com/install.sh | sh
sudo apt update

# [Windsurf]
curl -fsSL "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | sudo gpg --dearmor -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg arch=amd64] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null

# [ollama]
curl -fsSL https://ollama.com/install.sh | sh

# [ngrok]
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
  && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list \
  && sudo apt update \
  && sudo apt install ngrok

# [Program List]
sudo apt install snapd
sudo snap install snap-store

# [Snap Programs]

sudo snap install code --classic
sudo snap install pycharm-community --classic
sudo snap install pycharm-professional --classic
sudo snap install intellij-idea-community --classic
sudo snap install intellij-idea-ultimate --classic
sudo snap install webstorm --classic
sudo snap install goland --classic
sudo snap install phpstorm --classic
sudo snap install rubymine --classic
sudo snap install clion --classic
sudo snap install datagrip --classic
sudo snap install rider --classic
sudo snap install android-studio --classic
sudo snap install postman
sudo snap install slack
sudo snap install discord
sudo snap install skype
sudo snap install zoom-client
sudo snap install spotify
sudo snap install vlc
sudo snap install chromium
sudo snap install firefox
sudo snap install opera
sudo snap install thunderbird
sudo snap install gimp
sudo snap install inkscape
sudo snap install blender
sudo snap install kdenlive
sudo snap install obs-studio
sudo snap install docker
sudo snap install kubectl --classic
sudo snap install helm --classic
sudo snap install microk8s --classic
sudo snap install lxd
sudo snap install multipass
sudo snap install node --classic
sudo snap install yarn
sudo snap install dotnet-sdk --classic
sudo snap install powershell --classic
sudo snap install terraform
sudo snap install aws-cli --classic


[Open Tofu] [If RedHat]
# Download the installer script:
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
# Alternatively: wget --secure-protocol=TLSv1_2 --https-only https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh

# Give it execution permissions:
chmod +x install-opentofu.sh

# Please inspect the downloaded script

# Run the installer:
./install-opentofu.sh --install-method rpm

# Remove the installer:
rm -f install-opentofu.sh

# [ZeroTier]
curl -s https://install.zerotier.com | sudo bash
echo 'you will need to run something like zerotier-cli xxxxxxxxx with your net ID'

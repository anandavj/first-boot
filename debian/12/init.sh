#!/bin/bash

# Ensure a target user is provided
if [ -z "$1" ]; then
  echo "Error: No target user provided."
  echo "Usage: $0 <target_user>"
  exit 1
fi

TARGET_USER=$1

# Fix Hostname not Resolve
echo "Fix Hostname not Resolve"
sed -i "/^127.0.1.1/d" /etc/hosts
echo "127.0.1.1  $TARGET_USER" >> /etc/hosts

# Update and Upgrade
echo "Update and Upgrade"
sudo apt-get install update -y && sudo apt-get install upgrade -y

# Create User and Add user to sudoer
echo "Create User and Add user to sudoer"
TARGET_USER_PASSWORD=$(openssl rand -base64 12)
sudo adduser  --disabled-password --gecos "" "$TARGET_USER"
echo "$TARGET_USER:$TARGET_USER_PASSWORD" | sudo chpasswd
sudo usermod -aG sudo $TARGET_USER
echo "Default Password: ${TARGET_USER_PASSWORD}"
# Prompt Expire User Password
sudo passwd -e $TARGET_USER

# Create SSH Folder and give access to TARGET_USER
echo "Create SSH Folder and give access to $TARGET_USER"
mkdir /home/${TARGET_USER}/.ssh
touch /home/${TARGET_USER}/.ssh/authorized_keys
sudo chmod 700 /home/${TARGET_USER}/.ssh
sudo chmod 600 /home/${TARGET_USER}/.ssh/authorized_keys
sudo chown -R ${TARGET_USER}:${TARGET_USER} /home/${TARGET_USER}/.ssh

# Create SSH Key
echo "Create SSH Key"
ssh-keygen -q -t rsa -N '' -f /home/${TARGET_USER}/.ssh/id_rsa <<<y >/dev/null 2>&1
echo "Printing Private Key"
cat /home/${TARGET_USER}/.ssh/id_rsa
cat /home/${TARGET_USER}/.ssh/id_rsa.pub >> /home/${TARGET_USER}/.ssh/authorized_keys

# Backup Original sshd_config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Edit sshd_config
echo "Edit sshd_config"
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?AuthorizedKeysFile .*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?Port .*/Port 2433/' /etc/ssh/sshd_config

# Verify
grep -E "PasswordAuthentication|ChallengeResponseAuthentication|PubkeyAuthentication|PermitRootLogin|Port" /etc/ssh/sshd_config
sudo systemctl restart ssh

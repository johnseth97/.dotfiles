#!/bin/bash

# Script to set up GitHub integration: SSH keys, GPG signing, and Git user config
# Author: johnseth97

GREEN='\033[1;32m'
BLUE='\033[1;34m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Function to prompt user
prompt() {
  read -p "$1" response
  echo "$response"
}

# 1. Configure Git User Information
echo -e "${BLUE}Step 1: Configure Git User Information${NC}"
GIT_NAME=$(prompt "Enter your GitHub username (full name): ")
GIT_EMAIL=$(prompt "Enter your GitHub email: ")

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

echo -e "${GREEN}Git user information configured.${NC}\n"

# 2. Generate SSH Key
echo -e "${BLUE}Step 2: Generate and Add SSH Key${NC}"
SSH_KEY_PATH=~/.ssh/id_ed25519
if [ -f "$SSH_KEY_PATH" ]; then
  echo -e "${GREEN}SSH key already exists at $SSH_KEY_PATH.${NC}"
else
  echo -e "Generating SSH key..."
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH" -N ""
  eval "$(ssh-agent -s)"
  ssh-add "$SSH_KEY_PATH"
  echo -e "${GREEN}SSH key generated and added to the SSH agent.${NC}"
fi

echo -e "Your SSH public key is:\n"
cat "${SSH_KEY_PATH}.pub"
echo -e "${BLUE}Copy the above SSH public key and add it to GitHub SSH keys:${NC}"
echo "https://github.com/settings/keys"

prompt "Press Enter after you have added the SSH key to GitHub..."

# 3. Generate GPG Key
echo -e "\n${BLUE}Step 3: Generate and Configure GPG Key for Commit Signing${NC}"
if gpg --list-secret-keys --keyid-format=long | grep -q "sec"; then
  echo -e "${GREEN}GPG key already exists.${NC}"
else
  echo -e "Generating a new GPG key..."
  gpg --batch --gen-key <<EOF
  Key-Type: default
  Key-Length: 4096
  Subkey-Type: default
  Name-Real: $GIT_NAME
  Name-Email: $GIT_EMAIL
  Expire-Date: 0
  %commit
EOF
fi

GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep 'sec' | awk '{print $2}' | cut -d'/' -f2 | head -n 1)

if [ -n "$GPG_KEY_ID" ]; then
  echo -e "\n${BLUE}Your GPG key ID is: ${GPG_KEY_ID}${NC}"
  gpg --armor --export "$GPG_KEY_ID"
  echo -e "\n${BLUE}Copy the above GPG public key and add it to GitHub GPG keys:${NC}"
  echo "https://github.com/settings/keys"
  prompt "Press Enter after you have added the GPG key to GitHub..."
else
  echo -e "${RED}Error: Could not generate or retrieve GPG key.${NC}"
fi

# Configure Git to use GPG for signing commits
git config --global user.signingkey "$GPG_KEY_ID"
git config --global commit.gpgsign true

echo -e "${GREEN}Git is now configured to sign commits using GPG.${NC}\n"

# 4. Test GitHub SSH Connection
echo -e "${BLUE}Step 4: Test GitHub SSH Connection${NC}"
ssh -T git@github.com
if [ $? -eq 1 ]; then
  echo -e "${GREEN}GitHub SSH connection successful!${NC}"
else
  echo -e "${RED}SSH connection failed. Please check your SSH key setup.${NC}"
fi

# Summary
echo -e "\n${GREEN}GitHub integration setup complete!${NC}"
echo -e "Your Git user info, SSH key, and GPG signing are all configured."


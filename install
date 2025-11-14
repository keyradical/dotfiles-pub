#!/usr/bin/env bash

set -e

CONFIG="install.conf.yaml"
DOTBOT_DIR="dotbot"
DOTBOT_BIN="bin/dotbot"
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "$ID" == "ubuntu" ]]; then
    OS="ubuntu"
  else
    echo "Unsupported Linux distribution: $ID"
    exit 1
  fi
else
  echo "Unsupported operating system: $OSTYPE"
  exit 1
fi

echo "Detected OS: $OS"

# Install packages
echo "Installing required packages..."
if [[ "$OS" == "macos" ]]; then
  # Check if Homebrew is installed
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Install packages with Homebrew
  brew install zsh tmux neovim lazygit starship
elif [[ "$OS" == "ubuntu" ]]; then
  # Update package list
  sudo apt update -y

  # Install zsh, tmux, neovim
  sudo apt install -y zsh tmux

  # Install neovim
  if ! command -v neovim &>/dev/null; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
  fi

  # Install lazygit
  if ! command -v lazygit &>/dev/null; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
  fi

  # Install starship
  if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
fi

# Change default shell to zsh
if [[ "$SHELL" != *"zsh"* ]]; then
  echo "Changing default shell to zsh..."
  if [[ "$OS" == "macos" ]]; then
    sudo chsh -s $(which zsh)
  elif [[ "$OS" == "ubuntu" ]]; then
    sudo chsh -s $(which zsh)
  fi
  echo "Default shell changed to zsh. You may need to log out and log back in for this to take effect."
fi

# Run dotbot installation
echo "Running dotbot installation..."
cd "${BASEDIR}"
git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
git submodule update --init --recursive "${DOTBOT_DIR}"

"${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" -d "${BASEDIR}" -c "${CONFIG}" "${@}"

# Run zsh install script
echo "Running zsh install script..."
if [[ -f "${HOME}/.config/zsh/install.zsh" ]]; then
  zsh "${HOME}/.config/zsh/install.zsh"
  echo "Zsh install script completed."
else
  echo "Warning: Zsh install script not found at ~/.config/zsh/install.zsh"
fi

echo "Installation complete!"

#!/bin/bash

PACKAGES=(
  unzip
  git
  tmux
  curl
  eza
  make
  cmake
  build-essential
  gcc
  fzf
  python3-pip
  xz-utils
  tar
)
CONFIG_REPO="https://github.com/ziggoon/configs"

# uncomment for detailed logs
# set -x

function log() {
  local level=${1:-INFO}
  shift
  local message="$@"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  local color=""
  case "${level^^}" in
  "DEBUG") color="\033[36m" ;; # Cyan
  "INFO") color="\033[32m" ;;  # Green
  "WARN") color="\033[33m" ;;  # Yellow
  "ERROR") color="\033[31m" ;; # Red
  *) color="\033[0m" ;;        # Default
  esac

  local reset="\033[0m"

  printf "${color}[%s] [%s] %s${reset}\n" "$timestamp" "${level^^}" "$message" >&2
}

function update_packages() {
  local packages=("$@")

  log "INFO" "Updating system package sources"
  if apt update -y &>/dev/null; then
    log "INFO" "System packages updated successfully"
  else
    log "WARN" "Failed to update package sources. Continuing, but you may want to take a look."
  fi

  log "INFO" "Upgrading packages"
  if apt full-upgrade -y &>/dev/null; then
    log "INFO" "Packages upgraded successfully"
  else
    log "WARN" "Failed to upgrade packages. Continuing, but you may want to take a look."
  fi
}

function install_packages() {
  local packages=("$@")

  log "INFO" "Installing ${packages[*]}"

  if apt install "${packages[@]}" -y &>/dev/null; then
    log "INFO" "Packages installed successfully"
  else
    log "ERROR" "Failed to install packages. Please review manually."
    set -x
    apt install "${packages[@]}"
    set -
    return 1
  fi

  log "INFO" "Installing ohmyzsh"

  if sudo -u "$SUDO_USER" bash -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc' &>/dev/null; then
    log "INFO" "successfully installed ohmyzsh"
  else
    log "ERROR" "Failed to install ohmyzsh"
  fi

  setup_configs

  log "INFO" "Installing homebrew"

  mkdir -p /home/linuxbrew/.linuxbrew
  chown -R $SUDO_USER:$SUDO_USER /home/linuxbrew/.linuxbrew

  if NONINTERACTIVE=1 sudo -u "$SUDO_USER" bash -c "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash" &>/dev/null; then
    log "INFO" "Homebrew installed successfully"
    echo >>/home/$SUDO_USER/.zshrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>/home/$SUDO_USER/.zshrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  else
    log "ERROR" "Failed to install homebrew"
  fi

  log "INFO" "Installing .NET"

  if sudo -u "$SUDO_USER" bash -c "curl -sSL https://builds.dotnet.microsoft.com/dotnet/scripts/v1/dotnet-install.sh | bash" &>/dev/null; then
    log "INFO" ".NET installed successfully"
    echo 'export PATH="$HOME/.dotnet:$PATH"' >>"/home/$SUDO_USER/.zshrc"
    echo 'export DOTNET_ROOT="$HOME/.dotnet"' >>"/home/$SUDO_USER/.zshrc"
  else
    log "ERROR" "Failed to install .NET"
    return 1
  fi

  log "INFO" "Installing rust"

  if sudo -u "$SUDO_USER" bash -c "curl --proto '=https' --tlsv1.2 -s https://sh.rustup.rs | sh -s -- -y -q" &>/dev/null; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >>"/home/$SUDO_USER/.zshrc"
    echo 'source $HOME/.cargo/env' >>"/home/$SUDO_USER/.profile"
    log "INFO" "Rust installed successfully"
  else
    log "ERROR" "Failed to install Rust"
    return 1
  fi

  log "INFO" "Installing golang"

  if ! sudo -u "$SUDO_USER" bash -c "curl -LsSf https://dl.google.com/go/go1.23.4.linux-amd64.tar.gz -o go.tgz"; then
    log "ERROR" "Failed to download Go"
    return 1
  fi

  if rm -rf /usr/local/go && tar -C /usr/local -xzf go.tgz; then
    log "INFO" "Go installed successfully"
    echo "export PATH=$PATH:/usr/local/go/bin" >>"/home/$SUDO_USER/.zshrc"
  else
    log "ERROR" "Failed to install Go"
    return 1
  fi

  log "INFO" "Installing zig"

  if curl "https://ziglang.org/builds/zig-linux-x86_64-0.14.0-dev.2628+5b5c60f43.tar.xz" -o /tmp/zig.tar.xz &>/dev/null; then
    if command -v tar &>/dev/null; then
      cd /tmp
      tar xf /tmp/zig.tar.xz
      cp /tmp/zig-linux-x86_64-0.14.0-dev.2628+5b5c60f43/zig /usr/local/bin/zig
      log "INFO" "Successfully installed zig"
    else
      log "ERROR" "tar not found"
    fi
  else
    log "ERROR" "Failed to install zig"
  fi

  log "INFO" "Installing uv"

  if sudo -u "$SUDO_USER" bash -c "curl -LsSf https://astral.sh/uv/install.sh | sh" &>/dev/null; then
    log "INFO" "uv installed successfully"
  else
    log "ERROR" "Failed to install uv"
    return 1
  fi

  log "INFO" "Installing neovim"

  if sudo -u "$SUDO_USER" bash -c "source /home/$SUDO_USER/.zshrc; command -v brew" &>/dev/null; then
    if sudo -u "$SUDO_USER" bash -c "source /home/$SUDO_USER/.zshrc; brew install neovim -f" &>/dev/null; then
      log "INFO" "Installed neovim successfully"
    fi
  else
    log "ERROR" "Failed to install neovim"
  fi
}

function setup_configs() {
  log "INFO" "Grabbing configs from $CONFIG_REPO"

  if command -v git &>/dev/null; then
    if git clone $CONFIG_REPO /tmp/configs &>/dev/null; then
      log "INFO" "Configs retrieved successfully"
    fi
  else
    log "ERROR" "Git not found"
    return
  fi

  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm &>/dev/null

  rm -rf /home/$SUDO_USER/.config/nvim
  cp -r /tmp/configs/nvim /home/$SUDO_USER/.config/nvim

  cp /tmp/configs/tmux/.tmux.conf /home/$SUDO_USER/.tmux.conf
  cp /tmp/configs/zsh/.zshrc /home/$SUDO_USER/.zshrc
  cp /tmp/configs/zsh/ziggoon.zsh-theme /home/$SUDO_USER/.oh-my-zsh/custom/themes/ziggoon.zsh-theme

  log "INFO" "Setup configs successfully"
}

function cleanup() {
  chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER
}

update_packages
install_packages "${PACKAGES[@]}"
cleanup

log "INFO" "Setup complete. Please run 'source ~/.zshrc' to reload your shell."

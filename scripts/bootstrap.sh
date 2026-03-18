#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${BLUE}>>> $1${NC}"
}

run_as_user() {
  sudo -H -u "$SUDO_USER" "$@"
}

install_linux_packages() {
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm "$@"
  elif command -v zypper >/dev/null 2>&1; then
    zypper --non-interactive install "$@"
  else
    print_error "Unsupported Linux package manager. Please install these packages manually: $*"
    exit 1
  fi
}

if [ "$(id -u)" -ne 0 ]; then
  print_error "This script must be run with sudo."
  print_message "Example: curl -fsSL https://raw.githubusercontent.com/iarchean/dotfiles/main/scripts/bootstrap.sh | sudo sh"
  exit 1
fi

if [ -z "$SUDO_USER" ]; then
  print_error "SUDO_USER is not set. This script expects to be run via sudo by a regular user."
  exit 1
fi

print_message "Bootstrap running as root, for user: $SUDO_USER"

USER_HOME="/home/$SUDO_USER"
OS_TYPE="linux"
if [ "$(uname -s)" = "Darwin" ]; then
  OS_TYPE="macos"
  USER_HOME="/Users/$SUDO_USER"
fi

DOTFILES_REPO_URL="https://github.com/iarchean/dotfiles.git"
DOTFILES_LOCAL_PATH="${USER_HOME}/dotfiles"
LOCAL_INIT_SCRIPT="${DOTFILES_LOCAL_PATH}/scripts/init.sh"

print_message "Detected OS: $OS_TYPE. User home: $USER_HOME"

print_step "Ensuring git is installed"
if command -v git >/dev/null 2>&1; then
  print_message "Git is already installed."
elif [ "$OS_TYPE" = "macos" ]; then
  print_message "Git not found. Triggering Xcode Command Line Tools installation..."
  run_as_user xcode-select --install || print_warning "Xcode tools installation may require manual confirmation."
  print_error "Install Xcode Command Line Tools, then re-run this script."
  exit 1
else
  print_message "Git not found. Installing with the system package manager..."
  install_linux_packages git
fi

print_step "Cloning or updating dotfiles"
if [ -d "$DOTFILES_LOCAL_PATH/.git" ]; then
  print_message "Dotfiles directory exists. Pulling latest changes..."
  run_as_user git -C "$DOTFILES_LOCAL_PATH" pull || print_warning "Failed to pull dotfiles. Continuing with existing version."
elif [ -d "$DOTFILES_LOCAL_PATH" ]; then
  print_warning "${DOTFILES_LOCAL_PATH} exists but is not a git repository. Skipping clone."
else
  run_as_user git clone "$DOTFILES_REPO_URL" "$DOTFILES_LOCAL_PATH" || {
    print_error "Failed to clone dotfiles repository."
    exit 1
  }
fi

if [ -d "$DOTFILES_LOCAL_PATH" ]; then
  chown -R "$SUDO_USER":"$(id -g "$SUDO_USER")" "$DOTFILES_LOCAL_PATH"
fi

if [ ! -f "$LOCAL_INIT_SCRIPT" ]; then
  print_error "Local init script not found at ${LOCAL_INIT_SCRIPT}."
  exit 1
fi

print_message "Running local init script from ${LOCAL_INIT_SCRIPT}"
exec env SUDO_USER="$SUDO_USER" bash "$LOCAL_INIT_SCRIPT"

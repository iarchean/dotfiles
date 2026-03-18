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

find_brew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
  elif [ -x "/opt/homebrew/bin/brew" ]; then
    echo "/opt/homebrew/bin/brew"
  elif [ -x "/usr/local/bin/brew" ]; then
    echo "/usr/local/bin/brew"
  fi
}

find_mise() {
  if command -v mise >/dev/null 2>&1; then
    command -v mise
  elif [ -x "$HOME/.local/bin/mise" ]; then
    echo "$HOME/.local/bin/mise"
  elif [ -x "$USER_HOME/.local/bin/mise" ]; then
    echo "$USER_HOME/.local/bin/mise"
  elif [ -x "/opt/homebrew/bin/mise" ]; then
    echo "/opt/homebrew/bin/mise"
  elif [ -x "/usr/local/bin/mise" ]; then
    echo "/usr/local/bin/mise"
  fi
}

find_stow() {
  if command -v stow >/dev/null 2>&1; then
    command -v stow
  elif [ -x "/opt/homebrew/bin/stow" ]; then
    echo "/opt/homebrew/bin/stow"
  elif [ -x "/usr/local/bin/stow" ]; then
    echo "/usr/local/bin/stow"
  fi
}

install_homebrew() {
  print_message "Homebrew not found. Installing Homebrew..."
  run_as_user env NONINTERACTIVE=1 bash -lc 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash'
}

install_mise() {
  print_message "mise not found. Installing mise..."
  run_as_user env HOME="$USER_HOME" sh -c 'curl -fsSL https://mise.run | sh'
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

print_message "Script running as root, for user: $SUDO_USER"

USER_HOME="/home/$SUDO_USER"
OS_TYPE="linux"
if [ "$(uname -s)" = "Darwin" ]; then
  OS_TYPE="macos"
  USER_HOME="/Users/$SUDO_USER"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_LOCAL_PATH="$(cd "${SCRIPT_DIR}/.." && pwd)"

print_message "Detected OS: $OS_TYPE. User home: $USER_HOME"
print_message "Using dotfiles at ${DOTFILES_LOCAL_PATH}"

if [ "$OS_TYPE" = "macos" ]; then
  print_step "macOS setup"
  BREW_BIN="$(find_brew)"
  if [ -z "$BREW_BIN" ]; then
    install_homebrew
    BREW_BIN="$(find_brew)"
  fi

  if [ -z "$BREW_BIN" ]; then
    print_error "Homebrew installation did not complete successfully."
    exit 1
  fi

  print_step "Restoring apps and CLI tools with Homebrew"
  run_as_user "$BREW_BIN" bundle --file "$DOTFILES_LOCAL_PATH/Brewfile"

  print_step "Restoring dotfiles with GNU Stow"
  STOW_BIN="$(find_stow)"
  if [ -z "$STOW_BIN" ]; then
    print_error "stow was not found after brew bundle."
    exit 1
  fi
  run_as_user "$STOW_BIN" --dir "$DOTFILES_LOCAL_PATH" --target "$USER_HOME" --restow .config .mackup

  print_step "Restoring development tools with mise"
  MISE_BIN="$(find_mise)"
  if [ -n "$MISE_BIN" ]; then
    run_as_user "$MISE_BIN" install
  else
    print_warning "mise was not found after brew bundle. Skipping 'mise install'."
  fi

  print_step "Applying macOS system preferences"
  if [ -f "$DOTFILES_LOCAL_PATH/.macos" ]; then
    run_as_user env HOME="$USER_HOME" bash "$DOTFILES_LOCAL_PATH/.macos" || print_warning "Failed to apply .macos automatically. Run it manually later."
  else
    print_warning "No .macos file found. Skipping macOS preferences."
  fi

  print_step "Next steps for macOS"
  echo -e "1. ${BLUE}Open a new terminal window${NC} so Homebrew and shell changes are loaded."
  echo -e "2. ${BLUE}If needed, re-run dotfile linking:${NC}"
  echo -e "   ${YELLOW}stow --dir ${DOTFILES_LOCAL_PATH} --target ${USER_HOME} --restow .config .mackup${NC}"
  echo -e "3. ${BLUE}If needed, re-run tool restore:${NC}"
  echo -e "   ${YELLOW}${MISE_BIN:-mise} install${NC}"
  echo -e "4. ${BLUE}Some macOS settings may require logout or restart.${NC}"
else
  print_step "Linux setup"
  if [ -n "$(find_stow)" ]; then
    print_message "GNU Stow is already installed."
  else
    print_message "Installing GNU Stow with the system package manager..."
    install_linux_packages stow
  fi

  print_step "Restoring dotfiles with GNU Stow"
  STOW_BIN="$(find_stow)"
  if [ -z "$STOW_BIN" ]; then
    print_error "stow is not available after installation."
    exit 1
  fi
  run_as_user "$STOW_BIN" --dir "$DOTFILES_LOCAL_PATH" --target "$USER_HOME" --restow .config .mackup

  print_step "Restoring development tools with mise"
  MISE_BIN="$(find_mise)"
  if [ -z "$MISE_BIN" ]; then
    install_mise
    MISE_BIN="$(find_mise)"
  fi

  if [ -n "$MISE_BIN" ]; then
    run_as_user "$MISE_BIN" install
  else
    print_warning "mise installation did not complete successfully. Run 'mise install' manually later."
  fi

  print_step "Next steps for Linux"
  echo -e "1. ${BLUE}Install any missing GUI apps or system packages manually.${NC}"
  echo -e "2. ${BLUE}If needed, re-run dotfile linking:${NC}"
  echo -e "   ${YELLOW}stow --dir ${DOTFILES_LOCAL_PATH} --target ${USER_HOME} --restow .config .mackup${NC}"
  echo -e "3. ${BLUE}If needed, re-run tool restore after installing mise:${NC}"
  echo -e "   ${YELLOW}${MISE_BIN:-mise} install${NC}"
fi

print_message "\nScript finished."

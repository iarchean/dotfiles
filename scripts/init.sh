#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
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

# --- Main Script ---

# 1. Check if running with sudo and get the actual user
if [ "$(id -u)" -ne 0 ]; then
  print_error "This script must be run with sudo."
  print_message "Example: curl -fsSL https://raw.githubusercontent.com/iarchean/dotfiles/main/scripts/init.sh | sudo sh"
  exit 1
fi

if [ -z "$SUDO_USER" ]; then
  print_error "SUDO_USER is not set. This script expects to be run via sudo by a regular user."
  exit 1
fi
print_message "Script running as root, for user: $SUDO_USER"

# Determine Home Directory based on OS for the SUDO_USER
USER_HOME="/home/$SUDO_USER"
OS_TYPE="linux" # Default to Linux
if [ "$(uname -s)" = "Darwin" ]; then
  OS_TYPE="macos"
  USER_HOME="/Users/$SUDO_USER"
fi
print_message "Detected OS: $OS_TYPE. User home: $USER_HOME"


# --- Step 1: Install Nix using Determinate Systems Installer ---
print_step "Installing Nix (if not already installed)"
if command -v nix >/dev/null 2>&1; then
  print_message "Nix is already installed."
else
  print_message "Nix not found. Installing Nix via Determinate Systems installer..."
  if curl --proto '=https' --tlsv1.2 -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm; then
    print_message "Nix installation script completed."
  else
    print_error "Nix installation failed."
    exit 1
  fi
fi

# Source Nix environment for the current root shell.
# This is crucial for subsequent Nix commands run as root (like darwin-rebuild switch).
if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
  . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  print_message "Sourced Nix profile for current root shell."
else
  print_warning "Could not source Nix profile for root shell. Subsequent Nix commands in this script might fail if run as root."
  # Attempt common alternative path for Determinate Systems installer if the above isn't found immediately
  if [ -f "/etc/profiles/per-user/$USER/etc/profile.d/nix-daemon.sh" ]; then # $USER here is root
    . "/etc/profiles/per-user/root/etc/profile.d/nix-daemon.sh" # More specific
     print_message "Sourced Nix profile (alternative path) for current root shell."
  elif [ -f "/etc/profile.d/nix-daemon.sh" ]; then
    . "/etc/profile.d/nix-daemon.sh"
    print_message "Sourced Nix profile (common /etc/profile.d path) for current root shell."
  else
     print_warning "Still could not source Nix profile for root. darwin-rebuild switch might fail."
  fi
fi


# --- Step 2: OS-Specific Actions ---

# Define dotfiles repository and local path
DOTFILES_REPO_URL="https://github.com/iarchean/dotfiles.git" # OR your specific repo
DOTFILES_LOCAL_PATH="${USER_HOME}/dotfiles" # Your dotfiles will be cloned here

if [ "$OS_TYPE" = "macos" ]; then
  print_step "macOS: Setting up system with Nix-Darwin"

  print_message "Ensuring git is installed for cloning dotfiles..."
  if ! command -v git >/dev/null 2>&1; then
    print_message "Git not found. Attempting to install Xcode Command Line Tools (this may require user interaction)."
    sudo -u "$SUDO_USER" xcode-select --install || print_warning "Xcode tools installation might need manual confirmation."
    print_message "Please ensure Xcode Command Line Tools are installed, then re-run if necessary or if git is still missing."
    if ! command -v git >/dev/null 2>&1; then
      print_error "Git still not found after attempting Xcode tools install. Please install git manually and re-run."
      exit 1
    fi
  fi

  print_message "Cloning/Updating dotfiles repository to ${DOTFILES_LOCAL_PATH} as user ${SUDO_USER}..."
  if [ -d "$DOTFILES_LOCAL_PATH" ]; then
    print_message "Dotfiles directory exists. Pulling latest changes..."
    # Ensure correct ownership for pull if needed, though clone/chown below should cover it
    sudo -u "$SUDO_USER" git -C "$DOTFILES_LOCAL_PATH" pull || print_warning "Failed to pull dotfiles. Continuing with existing version."
  else
    sudo -u "$SUDO_USER" git clone "$DOTFILES_REPO_URL" "$DOTFILES_LOCAL_PATH" || { print_error "Failed to clone dotfiles repository."; exit 1; }
  fi
  # Ensure correct ownership of the whole cloned repo
  sudo chown -R "$SUDO_USER":"$(id -g "$SUDO_USER")" "$DOTFILES_LOCAL_PATH"


  print_message "Building Nix-Darwin configuration as user $SUDO_USER..."
  print_message "This may take a while."
  BUILD_CMD="cd '${DOTFILES_LOCAL_PATH}/nix' && nix build .#darwinConfigurations.mac.system --impure"

  if ! sudo -u "$SUDO_USER" bash -c ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && ${BUILD_CMD}"; then
    print_error "Nix-Darwin build failed."
    print_message "Please check the output above for errors. Ensure your flake at ${DOTFILES_LOCAL_PATH}/nix/flake.nix is correct."
    exit 1
  fi
  print_message "Nix-Darwin configuration built successfully."

  print_message "Switching to new Nix-Darwin configuration (will be run as user $SUDO_USER, darwin-rebuild will use sudo internally)..."
  print_message "This might require your password for sudo operations within darwin-rebuild."

  # Run darwin-rebuild switch as the SUDO_USER.
  # darwin-rebuild will handle its own sudo elevation for system changes.
  # The 'cd' is crucial.
  SWITCH_CMD_AS_USER="cd '${DOTFILES_LOCAL_PATH}/nix' && ./result/sw/bin/darwin-rebuild switch --flake .#mac --impure"

  # Execute as the user, sourcing the Nix profile first.
  if sudo -u "$SUDO_USER" bash -c ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && ${SWITCH_CMD_AS_USER}"; then
    print_message "Nix-Darwin system switch completed."
  else
    print_error "Nix-Darwin switch failed."
    print_message "Please check the output above for errors. You might need to run the switch command manually as user ${SUDO_USER}:"
    echo -e "   ${YELLOW}cd ${DOTFILES_LOCAL_PATH}/nix${NC}"
    echo -e "   ${YELLOW}./result/sw/bin/darwin-rebuild switch --flake .#mac --impure${NC} (this will prompt for sudo password)"
    exit 1
  fi

  print_step "Next Steps for macOS User ($SUDO_USER):"
  echo -e "1. ${BLUE}Open a new terminal window${NC} to ensure all Nix environment changes are loaded."
  echo -e "2. Your system packages (including 'stow' if declared in your flake) are now installed."
  echo -e "3. To link your dotfiles using GNU Stow, run the following commands as user '${SUDO_USER}':"
  echo -e "   ${YELLOW}cd ${DOTFILES_LOCAL_PATH}${NC}"
  echo -e "   ${YELLOW}stow <package_name_1> <package_name_2> ...${NC} (e.g., stow nvim fish tmux)"
  echo -e "   (Replace <package_name_...> with the actual directory names inside ${DOTFILES_LOCAL_PATH} you want to link, e.g., 'nvim', 'fish', 'tmux')"
  echo -e "   Or, to stow all packages (subdirectories): ${YELLOW}stow */${NC}"


elif [ "$OS_TYPE" = "linux" ]; then
  print_step "Linux: Next Steps for User ($SUDO_USER)"
  echo -e "Nix has been installed. To configure your system and dotfiles:"
  echo -e "1. ${BLUE}Open a new terminal window or run the following command to activate Nix for your current session:${NC}"
  echo -e "   ${YELLOW}. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh${NC}"
  echo -e ""
  echo -e "2. ${BLUE}Clone your dotfiles repository (if you haven't already):${NC}"
  echo -e "   Make sure git is installed (e.g., ${YELLOW}sudo apt update && sudo apt install git${NC} on Debian/Ubuntu)."
  echo -e "   Then run: ${YELLOW}git clone ${DOTFILES_REPO_URL} ${DOTFILES_LOCAL_PATH}${NC}"
  echo -e "   And: ${YELLOW}cd ${DOTFILES_LOCAL_PATH}${NC}"
  echo -e ""
  echo -e "3. ${BLUE}Install GNU Stow and other essential tools using Nix:${NC}"
  echo -e "   You can install 'stow' (and other tools defined in your flake) to your user profile:"
  echo -e "   ${YELLOW}nix profile install nixpkgs#stow${NC}  (for just stow)"
  echo -e "   Or, if your flake exposes a package set (e.g., 'tools-linux'):"
  echo -e "   ${YELLOW}nix profile install .#tools-linux${NC} (run this from within ${DOTFILES_LOCAL_PATH})"
  echo -e "   Alternatively, enter a development shell with all tools:"
  echo -e "   ${YELLOW}nix develop .#env-linux${NC} (run this from within ${DOTFILES_LOCAL_PATH})"
  echo -e ""
  echo -e "4. ${BLUE}Link your dotfiles using GNU Stow:${NC}"
  echo -e "   Once 'stow' is available (either via nix profile or inside nix develop shell):"
  echo -e "   ${YELLOW}cd ${DOTFILES_LOCAL_PATH}${NC}"
  echo -e "   ${YELLOW}stow <package_name_1> <package_name_2> ...${NC} (e.g., stow nvim fish tmux)"
  echo -e "   Or, to stow all packages (subdirectories): ${YELLOW}stow */${NC}"
  echo -e ""
  echo -e "Your dotfiles flake (${DOTFILES_LOCAL_PATH}/flake.nix) likely contains configurations for these tools."

else
  print_error "Unsupported operating system: $(uname -s)"
  exit 1
fi

print_message "\nScript finished."
if [ "$OS_TYPE" = "macos" ]; then
  print_message "For macOS, some system changes might require a logout/login or restart."
fi
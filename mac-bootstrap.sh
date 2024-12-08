#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Basic functions for output
log() { echo "→ $1"; }
logk() { echo "✓ Done"; }
abort() { echo "✗ $1" >&2; exit 1; }

# Ensure running as non-root user with admin privileges
[[ $EUID -eq 0 ]] && abort "Run this script as yourself, not root."
groups | grep -q admin || abort "Add $USER to the admin group."

# Keep system awake during script
caffeinate -s -w $$ &

# Configure TouchID for sudo if available
if [[ -f /usr/lib/pam/pam_tid.so ]]; then
    log "Configuring TouchID for sudo"
    PAM_FILE="/etc/pam.d/sudo_local"
    if [[ ! -f $PAM_FILE ]]; then
        echo "# sudo_local: local config file which survives system update" | sudo tee "$PAM_FILE" >/dev/null
        echo "auth       sufficient     pam_tid.so" | sudo tee -a "$PAM_FILE" >/dev/null
    elif ! grep -q "pam_tid.so" "$PAM_FILE"; then
        echo "auth       sufficient     pam_tid.so" | sudo tee -a "$PAM_FILE" >/dev/null
    fi
    logk
fi

# Check and enable FileVault if needed
log "Checking FileVault status"
if ! fdesetup status | grep -q "FileVault is On"; then
    log "Enabling FileVault"
    sudo fdesetup enable -user "$USER" | tee ~/Desktop/"FileVault Recovery Key.txt"
fi
logk

# Install Xcode Command Line Tools
if ! [ -f "/Library/Developer/CommandLineTools/usr/bin/git" ]; then
    log "Installing Xcode Command Line Tools"
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    PROD=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
    softwareupdate -i "$PROD" --verbose
    rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    logk
fi

# Accept Xcode license if needed
if /usr/bin/xcrun clang 2>&1 | grep -q license; then
    log "Accepting Xcode license"
    sudo xcodebuild -license accept
    logk
fi

# Install/Update Homebrew
log "Setting up Homebrew"
if [[ $(uname -m) == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

if [[ ! -f "$HOMEBREW_PREFIX/bin/brew" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
fi

/opt/homebrew/bin/brew update
logk

# Install from local Brewfile
if [ -f "$SCRIPT_DIR/Brewfile" ]; then
    log "Installing packages from Brewfile"
    # Add Homebrew to PATH if needed
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    brew bundle --file="$SCRIPT_DIR/Brewfile"
    logk
else
    abort "No Brewfile found in repository"
fi

# Setup dotfiles with chezmoi
log "Setting up dotfiles with chezmoi"
if ! command -v chezmoi >/dev/null 2>&1; then
    brew install chezmoi
fi

# Initialize chezmoi
if [ ! -d "$HOME/.local/share/chezmoi" ]; then
    log "Initializing chezmoi with dotfiles repository"
    chezmoi init git@github.com:neowim/dotfiles.git
    echo "⚠️  You will be prompted for your encryption passphrase to decrypt sensitive files"
else
    log "Updating existing chezmoi configuration"
    chezmoi update
fi

# Apply dotfiles configuration
log "Applying dotfiles configuration"
chezmoi apply
logk

# Check for system updates
log "Checking for system updates"
if ! softwareupdate -l 2>&1 | grep -q "No new software available"; then
    sudo softwareupdate --install --all
fi
logk

# Configure macOS settings
log "Configuring macOS defaults"
bash "$SCRIPT_DIR/defaults.sh"
logk

log "System setup complete! 🎉"
echo "Note: Please manually configure these security settings in System Settings:"
echo "1. Security & Privacy → Require password immediately after sleep or screen saver begins"
echo "2. Security & Privacy → Turn on Firewall"

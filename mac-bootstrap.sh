#!/usr/bin/env bash
#
# A macOS provisioning and setup script with improvements:
# - Centralized configuration
# - Timestamped logging (date and time) to both console and a log file
# - Log file name includes date and time
# - Functions for repeated checks
# - Optional flags to skip certain steps (e.g., --skip-filevault, --skip-brewfile, --skip-updates)
# - Pre-run summary of planned actions
# - Environment checks (network connectivity)
# - Clear logging and error reporting, recorded in a dated log file
#
# Usage:
#   ./setup.sh [OPTIONS]
#
# Options:
#   --skip-filevault     Do not enable FileVault or check its status
#   --skip-brewfile      Do not run 'brew bundle' to install packages from the Brewfile
#   --skip-updates       Do not check for or install system updates
#
# Example:
#   ./setup.sh --skip-filevault --skip-updates

###############################################################################
# Configuration Section
###############################################################################
HOMEBREW_PREFIX_ARM64="/opt/homebrew"
HOMEBREW_PREFIX_INTEL="/usr/local"
DOTFILES_REPO="https://github.com/neowim/dotfiles.git"
BREWFILE_NAME="Brewfile"
DEFAULTS_SCRIPT_NAME="defaults.sh"

# Default action flags
SKIP_FILEVAULT=false
SKIP_BREWFILE=false
SKIP_UPDATES=false

###############################################################################
# Argument Parsing
###############################################################################
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-filevault) SKIP_FILEVAULT=true; shift ;;
        --skip-brewfile)  SKIP_BREWFILE=true; shift ;;
        --skip-updates)   SKIP_UPDATES=true; shift ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

###############################################################################
# Set up Logging
###############################################################################
# Determine script directory and log file name with date/time
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/setup_$(date '+%Y-%m-%d_%H-%M-%S').log"

# Timestamp function for logs
timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

# Logging functions
log()   { echo "$(timestamp) → $*"; }
logk()  { echo "$(timestamp) ✓ $*"; }
warn()  { echo "$(timestamp) ⚠️  $*" >&2; }
abort() { echo "$(timestamp) ✗ $*" >&2; exit 1; }

# Write initial log header
{
    echo "========================"
    echo "Log started at: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================"
} | tee "$LOG_FILE"

# Redirect all output (stdout and stderr) to tee, which writes to both console and log file
exec > >(tee -a "$LOG_FILE") 2>&1

try_command() {
    if ! "$@"; then
        warn "Command failed: $*"
        return 1
    fi
    return 0
}

check_installed() {
    # Usage: check_installed <command> <message if missing>
    local cmd="$1"
    local install_msg="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "$install_msg"
        return 1
    fi
    return 0
}

###############################################################################
# Pre-Run Summary
###############################################################################
log "Preparation Summary:"
log "  - Skip FileVault:   $SKIP_FILEVAULT"
log "  - Skip Brewfile:    $SKIP_BREWFILE"
log "  - Skip Updates:     $SKIP_UPDATES"
log "  - Dotfiles Repo:    $DOTFILES_REPO"
log "  - Brewfile Name:    $BREWFILE_NAME"
log "  - Defaults Script:  $DEFAULTS_SCRIPT_NAME"
log ""
log "About to configure your system with these settings..."
sleep 2

###############################################################################
# Basic Checks and Setup
###############################################################################
set +e
trap 'if [ $? -ne 0 ]; then warn "Script failed with exit code $?"; fi' EXIT

[[ $EUID -eq 0 ]] && abort "Run this script as yourself, not root."
groups | grep -q admin || abort "Add $USER to the admin group."

caffeinate -s -w $$ &

###############################################################################
# Environment Checks
###############################################################################
log "Checking network connectivity..."
if ping -c1 8.8.8.8 &>/dev/null; then
    logk "Network connectivity confirmed"
else
    abort "No network connectivity detected. Please ensure you're online."
fi

###############################################################################
# TouchID for sudo
###############################################################################
PAM_TID_PATH=$(find /usr/lib/pam -name 'pam_tid.so*' 2>/dev/null | head -n 1)
if [[ -n "$PAM_TID_PATH" ]]; then
    log "Configuring TouchID for sudo using $PAM_TID_PATH"
    PAM_FILE="/etc/pam.d/sudo_local"
    if [[ ! -f $PAM_FILE ]]; then
        echo "# sudo_local: local config file which survives system update" | sudo tee "$PAM_FILE" >/dev/null
        echo "auth       sufficient     pam_tid.so" | sudo tee -a "$PAM_FILE" >/dev/null
    elif ! grep -q "pam_tid.so" "$PAM_FILE"; then
        echo "auth       sufficient     pam_tid.so" | sudo tee -a "$PAM_FILE" >/dev/null
    fi
    logk "TouchID configured"
else
    log "TouchID not available on this system"
fi

###############################################################################
# FileVault Encryption
###############################################################################
if ! $SKIP_FILEVAULT; then
    log "Checking FileVault status"
    if ! fdesetup status | grep -q "FileVault is On"; then
        log "Enabling FileVault"
        sudo fdesetup enable -user "$USER" | tee ~/Desktop/"FileVault Recovery Key.txt" || warn "Failed to enable FileVault"
    fi
    logk "FileVault checked"
else
    log "Skipping FileVault setup"
fi

###############################################################################
# Xcode Command Line Tools
###############################################################################
if ! [ -f "/Library/Developer/CommandLineTools/usr/bin/git" ]; then
    log "Installing Xcode Command Line Tools"
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    PROD=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
    softwareupdate -i "$PROD" --verbose || warn "Command Line Tools installation failed"
    rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    logk "Xcode Command Line Tools installed"
else
    logk "Xcode Command Line Tools already installed"
fi

# Accept Xcode license if needed
if /usr/bin/xcrun clang 2>&1 | grep -q license; then
    log "Accepting Xcode license"
    sudo xcodebuild -license accept || warn "Failed to accept Xcode license"
    logk "Xcode license accepted"
fi

###############################################################################
# Homebrew Setup
###############################################################################
log "Setting up Homebrew"
if [[ $(uname -m) == "arm64" ]]; then
    HOMEBREW_PREFIX="$HOMEBREW_PREFIX_ARM64"
else
    HOMEBREW_PREFIX="$HOMEBREW_PREFIX_INTEL"
fi

if [[ ! -f "$HOMEBREW_PREFIX/bin/brew" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || warn "Homebrew installation failed"
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
fi

try_command $HOMEBREW_PREFIX/bin/brew update
logk "Homebrew setup complete"

###############################################################################
# Brewfile Installation
###############################################################################
if ! $SKIP_BREWFILE; then
    if [ -f "$SCRIPT_DIR/$BREWFILE_NAME" ]; then
        log "Installing packages from $BREWFILE_NAME"
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$($HOMEBREW_PREFIX_ARM64/bin/brew shellenv)"
        else
            eval "$($HOMEBREW_PREFIX_INTEL/bin/brew shellenv)"
        fi
        try_command brew bundle --file="$SCRIPT_DIR/$BREWFILE_NAME" || warn "Some Homebrew installations failed, continuing"
        logk "Brewfile installations complete"
    else
        warn "No $BREWFILE_NAME found in repository; skipping related package installations"
    fi
else
    log "Skipping Brewfile installations as requested"
fi

###############################################################################
# Dotfiles with chezmoi
###############################################################################
log "Setting up dotfiles with chezmoi"
check_installed chezmoi "Installing chezmoi" || brew install chezmoi

if [ ! -d "$HOME/.local/share/chezmoi" ]; then
    log "Initializing chezmoi with dotfiles repository"
    chezmoi init "$DOTFILES_REPO" || warn "Failed to initialize chezmoi repository"
    echo "Note: After setting up SSH keys, switch to SSH remote with:"
    echo "cd ~/.local/share/chezmoi && git remote set-url origin git@github.com:neowim/dotfiles.git"
else
    log "Updating existing chezmoi configuration"
    chezmoi update || warn "Failed to update chezmoi configuration"
fi

log "Applying dotfiles configuration"
chezmoi apply || warn "chezmoi apply encountered issues"
logk "Dotfiles applied"

###############################################################################
# Zsh Plugins and Themes
###############################################################################
log "Setting up Zsh plugins and themes"
mkdir -p ~/.zsh/{plugins,themes}

# Powerlevel10k
if [ ! -d ~/.zsh/themes/powerlevel10k ]; then
    try_command git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/themes/powerlevel10k
fi

# Common Zsh Plugins
PLUGINS=(
    "zsh-users/zsh-completions"
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-history-substring-search"
    "zsh-users/zsh-syntax-highlighting"
)

for repo in "${PLUGINS[@]}"; do
    plugin_name=$(basename "$repo")
    if [ ! -d ~/.zsh/plugins/"$plugin_name" ]; then
        try_command git clone --depth=1 https://github.com/"$repo".git ~/.zsh/plugins/"$plugin_name"
    fi
done
logk "Zsh plugins and themes setup complete"

###############################################################################
# System Updates
###############################################################################
if ! $SKIP_UPDATES; then
    log "Checking for system updates"
    UPDATE_LIST=$(softwareupdate -l 2>&1)
    if echo "$UPDATE_LIST" | grep -q "No new software available"; then
        logk "No new system updates available"
    else
        log "Available updates:"
        echo "$UPDATE_LIST" | grep "recommended"
        log "Installing updates..."
        sudo softwareupdate --install --all || warn "Some updates failed"
        logk "System updates complete"
    fi
else
    log "Skipping system updates as requested"
fi

###############################################################################
# macOS Defaults Configuration
###############################################################################
if [ -f "$SCRIPT_DIR/$DEFAULTS_SCRIPT_NAME" ]; then
    log "Configuring macOS defaults"
    bash "$SCRIPT_DIR/$DEFAULTS_SCRIPT_NAME" || warn "Defaults script encountered issues"
    logk "macOS defaults configured"
else
    warn "No $DEFAULTS_SCRIPT_NAME found, skipping macOS defaults configuration"
fi

###############################################################################
# Final Notes
###############################################################################
log "System setup complete! 🎉"
log "Log file saved at: $LOG_FILE"
echo "Please manually configure these security settings in System Settings:"
echo "1. Security & Privacy → Require password immediately after sleep or screen saver begins"
echo "2. Security & Privacy → Turn on Firewall"

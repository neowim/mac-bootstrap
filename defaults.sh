#!/usr/bin/env bash

# Exit on error
set -e

echo "Configuring macOS settings..."

# Close System Preferences to prevent override
osascript -e 'tell application "System Preferences" to quit'

echo "Configuring System Preferences..."
# System UI/UX
defaults write NSGlobalDomain AppleInterfaceStyle Dark
defaults write NSGlobalDomain AppleWindowTabbingMode always
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
defaults write NSGlobalDomain com.apple.mouse.scaling -float "2.5"
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

# Disable automatic substitutions
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Performance improvements
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.dock "orientation" -string "left"

echo "Configuring Dock..."
# Dock settings
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-time-modifier -float "0"
defaults write com.apple.dock autohide-delay -float "0"

echo "Configuring Finder..."
# Finder settings
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder WarnOnEmptyTrash -bool false
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXRemoveOldTrashItems -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true

# Desktop settings
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Clean up .DS_Store files
rm -rf ~/.DS_Store

echo "Restarting Finder and Dock..."
# Restart affected applications
killall Dock
killall Finder

echo "macOS settings updated successfully!"
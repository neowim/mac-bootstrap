#!/usr/bin/env bash

# Close open System Preferences panes, to prevent them from overriding settings.
osascript -e 'tell application "System Preferences" to quit'

defaults write NSGlobalDomain AppleInterfaceStyle Dark

defaults write NSGlobalDomain AppleWindowTabbingMode always

defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.dock "orientation" -string "left"

defaults write com.apple.dock "autohide" -bool "true"

defaults write com.apple.dock "autohide-time-modifier" -float "0" && killall Dock

defaults write com.apple.dock "autohide-delay" -float "0" && killall Dock

defaults write com.apple.finder "AppleShowAllFiles" -bool "true"

defaults write com.apple.finder "ShowPathbar" -bool "true"

defaults write com.apple.finder "ShowStatusBar" -bool "true"

defaults write com.apple.finder "FXPreferredViewStyle" -string "Nlsv"
rm -rf ~/.DS_Store

defaults write com.apple.finder "NewWindowTarget" -string "PfHm"



defaults write com.apple.finder WarnOnEmptyTrash -bool false

defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true"

defaults write NSGlobalDomain "NSAutomaticWindowAnimationsEnabled" -bool "false"

defaults write NSGlobalDomain "NSWindowResizeTime" -float "0.001"

defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"

defaults write com.apple.finder "FXRemoveOldTrashItems" -bool "true"

defaults write com.apple.finder "FXEnableExtensionChangeWarning" -bool "false"

defaults write com.apple.finder "_FXSortFoldersFirstOnDesktop" -bool "true"

defaults write com.apple.finder "ShowHardDrivesOnDesktop" -bool "true"

defaults write com.apple.finder "ShowExternalHardDrivesOnDesktop" -bool "true"

defaults write com.apple.finder "ShowMountedServersOnDesktop" -bool "true"

defaults write NSGlobalDomain com.apple.mouse.scaling -float "2.5"

defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true




killall Dock && killall Finder
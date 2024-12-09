# Mac Bootstrap

A script to automate the setup of a new Mac with my preferred configuration, applications, and dotfiles. This repository contains everything needed to go from a fresh macOS installation to a fully configured development environment.

## Features

- 🔐 Security First
  - Configures TouchID for sudo authentication
  - Enables FileVault disk encryption
  - Sets secure defaults
- 🛠 Development Setup
  - Installs Xcode Command Line Tools
  - Sets up Homebrew and essential packages
  - Configures development tools and languages
- ⚙️ System Configuration
  - Sets up macOS system preferences
  - Configures dock, finder, and UI preferences
  - Installs preferred applications via Homebrew
- 📁 Dotfiles Management
  - Automatically sets up dotfiles using chezmoi
  - Maintains configuration in a separate repository

## Prerequisites

- A Mac running macOS
- Admin user account
- Internet connection
- Your encryption passphrase (for encrypted dotfiles)

## Usage

1. Install Xcode Command Line Tools first:
```bash
xcode-select --install
```

2. Clone this repository:
```bash
git clone https://github.com/neowim/mac-bootstrap.git
cd mac-bootstrap
```

3. Review and customize the `Brewfile`:
   - Comment out any packages you don't want
   - Add any additional packages you need
   - Update Mac App Store application IDs if needed

4. Make the script executable and run it:
```bash
chmod +x mac-bootstrap.sh
./mac-bootstrap.sh
```

5. Follow any prompts for:
   - System password
   - Mac App Store authentication
   - Encryption passphrase (for encrypted dotfiles)

## Customization

### Brewfile
The `Brewfile` contains all packages, applications, and fonts that will be installed. It's organized into sections:
- System dependencies
- Development tools
- GUI Applications
- Fonts
- Mac App Store applications
- VS Code extensions

### System Preferences
The `defaults.sh` script contains macOS system preferences. Edit this file to customize:
- UI preferences
- Finder settings
- Dock configuration
- System behavior

## Structure

- `mac-bootstrap.sh`: Main installation script
- `Brewfile`: Package and application definitions
- `defaults.sh`: macOS system preferences
- `.gitignore`: Git ignore rules

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Feel free to fork this repository and customize it for your own use. If you have improvements that might benefit others, pull requests are welcome!

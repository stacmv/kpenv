#!/bin/bash
# kpenv installer
# Installs kpenv to /usr/local/bin and sets up configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔧 Installing kpenv (KeePass Environment Manager)..."
echo ""

# Check if running as root for system install
INSTALL_DIR="/usr/local/bin"
if [ ! -w "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Note: Will need sudo for system-wide installation${NC}"
    USE_SUDO="sudo"
else
    USE_SUDO=""
fi

# 1. Check PHP
echo "Checking dependencies..."
if ! command -v php >/dev/null 2>&1; then
    echo -e "${RED}✗ PHP not found${NC}"
    echo "Please install PHP 8.2 or higher:"
    echo "  Ubuntu/Debian: sudo apt install php-cli"
    echo "  macOS: brew install php"
    exit 1
fi

# Check PHP version
php_version=$(php -r 'echo PHP_VERSION;')
required_version="8.2.0"

# Version comparison
if [ "$(printf '%s\n' "$required_version" "$php_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo -e "${RED}✗ PHP 8.2+ required (found $php_version)${NC}"
    echo "Please upgrade PHP:"
    echo "  Ubuntu/Debian: sudo apt install php8.2-cli"
    echo "  macOS: brew install php@8.2"
    exit 1
fi

echo -e "${GREEN}✓${NC} PHP $php_version found"

# 2. Check KeePassXC CLI (warn but don't fail)
if ! command -v keepassxc-cli >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠${NC} keepassxc-cli not found"
    echo "  KeePassXC is needed for backup/restore features"
    echo "  Install with:"
    echo "    Ubuntu/Debian: sudo apt install keepassxc"
    echo "    macOS: brew install keepassxc"
    echo ""
    echo "  Continue without KeePassXC? [y/N]"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} keepassxc-cli found"
fi

echo ""

# 3. Install kpenv executable
echo "Installing kpenv..."

if [ -f "./kpenv" ]; then
    # Local installation
    echo "Installing from local file..."
    $USE_SUDO cp kpenv "$INSTALL_DIR/kpenv"
elif [ -n "$KPENV_INSTALL_URL" ]; then
    # Remote installation from custom URL
    echo "Downloading from $KPENV_INSTALL_URL..."
    if command -v curl >/dev/null 2>&1; then
        curl -sSL "$KPENV_INSTALL_URL" -o /tmp/kpenv
    elif command -v wget >/dev/null 2>&1; then
        wget -qO /tmp/kpenv "$KPENV_INSTALL_URL"
    else
        echo -e "${RED}✗ Neither curl nor wget found${NC}"
        exit 1
    fi
    $USE_SUDO mv /tmp/kpenv "$INSTALL_DIR/kpenv"
else
    # Default remote installation
    GITHUB_URL="https://raw.githubusercontent.com/stacmv/env-manager/main/kpenv"
    echo "Downloading from GitHub..."
    if command -v curl >/dev/null 2>&1; then
        curl -sSL "$GITHUB_URL" -o /tmp/kpenv || {
            echo -e "${RED}✗ Download failed${NC}"
            echo "Please install from local directory or check network connection"
            exit 1
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -qO /tmp/kpenv "$GITHUB_URL" || {
            echo -e "${RED}✗ Download failed${NC}"
            echo "Please install from local directory or check network connection"
            exit 1
        }
    else
        echo -e "${RED}✗ Neither curl nor wget found${NC}"
        exit 1
    fi
    $USE_SUDO mv /tmp/kpenv "$INSTALL_DIR/kpenv"
fi

# 4. Make executable
$USE_SUDO chmod +x "$INSTALL_DIR/kpenv"
echo -e "${GREEN}✓${NC} Installed to $INSTALL_DIR/kpenv"

# 5. Create config directory
echo ""
echo "Setting up configuration..."
mkdir -p ~/.kpenv

# 6. Create default config if not exists
if [ ! -f ~/.kpenv/config.json ]; then
    HOME_DIR="$HOME"
    cat > ~/.kpenv/config.json <<EOF
{
  "base_dev_folder": "$HOME_DIR/dev",
  "keepass_db": "$HOME_DIR/Documents/work-secrets.kdbx",
  "default_env": "development",
  "example_files": [
    ".env.example",
    "env.example",
    ".env.dist",
    "example.env"
  ],
  "auto_gitignore": true
}
EOF
    echo -e "${GREEN}✓${NC} Created default config at ~/.kpenv/config.json"
    echo "  You can edit this file to customize paths"
else
    echo -e "${GREEN}✓${NC} Config already exists at ~/.kpenv/config.json"
fi

# 7. Install shell completions
echo ""
echo "Setting up shell completions..."

# Detect shell and install appropriate completions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Bash completion
BASH_COMPLETION_INSTALLED=false
if [ -f "$SCRIPT_DIR/completions/kpenv.bash" ]; then
    # Try system-wide first
    if [ -d "/etc/bash_completion.d" ] && [ -w "/etc/bash_completion.d" ]; then
        $USE_SUDO cp "$SCRIPT_DIR/completions/kpenv.bash" /etc/bash_completion.d/kpenv
        BASH_COMPLETION_INSTALLED=true
        echo -e "${GREEN}✓${NC} Bash completion installed to /etc/bash_completion.d/kpenv"
    elif [ -d "/usr/local/etc/bash_completion.d" ]; then
        # macOS Homebrew location
        $USE_SUDO cp "$SCRIPT_DIR/completions/kpenv.bash" /usr/local/etc/bash_completion.d/kpenv
        BASH_COMPLETION_INSTALLED=true
        echo -e "${GREEN}✓${NC} Bash completion installed to /usr/local/etc/bash_completion.d/kpenv"
    else
        # User-local installation
        mkdir -p ~/.local/share/bash-completion/completions
        cp "$SCRIPT_DIR/completions/kpenv.bash" ~/.local/share/bash-completion/completions/kpenv
        BASH_COMPLETION_INSTALLED=true
        echo -e "${GREEN}✓${NC} Bash completion installed to ~/.local/share/bash-completion/completions/kpenv"
    fi
fi

# Zsh completion
ZSH_COMPLETION_INSTALLED=false
if [ -f "$SCRIPT_DIR/completions/_kpenv" ]; then
    # Create user completions directory if using zsh
    if [ -n "$ZSH_VERSION" ] || [ -f ~/.zshrc ]; then
        mkdir -p ~/.zsh/completions
        cp "$SCRIPT_DIR/completions/_kpenv" ~/.zsh/completions/_kpenv
        ZSH_COMPLETION_INSTALLED=true
        echo -e "${GREEN}✓${NC} Zsh completion installed to ~/.zsh/completions/_kpenv"

        # Check if fpath is configured
        if ! grep -q 'fpath.*\.zsh/completions' ~/.zshrc 2>/dev/null; then
            echo -e "${YELLOW}⚠${NC} Add this to your ~/.zshrc to enable completions:"
            echo '  fpath=(~/.zsh/completions $fpath)'
            echo '  autoload -Uz compinit && compinit'
        fi
    fi
fi

if [ "$BASH_COMPLETION_INSTALLED" = false ] && [ "$ZSH_COMPLETION_INSTALLED" = false ]; then
    echo -e "${YELLOW}⚠${NC} Shell completions not installed (completion files not found)"
fi

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo "Quick start:"
echo "  cd your-project"
echo "  kpenv init          # Initialize project"
echo "  kpenv --help        # Show all commands"
echo ""
echo "Configuration:"
echo "  ~/.kpenv/config.json  - User settings"
echo ""
echo "Note: Make sure $INSTALL_DIR is in your PATH"

#!/bin/bash
# kpenv uninstaller
# Removes kpenv from system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🗑️  Uninstalling kpenv..."
echo ""

INSTALL_DIR="/usr/local/bin"

# Check if we need sudo
if [ ! -w "$INSTALL_DIR" ]; then
    USE_SUDO="sudo"
else
    USE_SUDO=""
fi

# Remove binary
if [ -f "$INSTALL_DIR/kpenv" ]; then
    echo "Removing kpenv binary..."
    $USE_SUDO rm -f "$INSTALL_DIR/kpenv"
    echo -e "${GREEN}✓${NC} Removed $INSTALL_DIR/kpenv"
else
    echo -e "${YELLOW}⚠${NC} kpenv not found in $INSTALL_DIR"
fi

echo ""

# Ask about config
if [ -d ~/.kpenv ]; then
    echo "Configuration directory exists: ~/.kpenv"
    echo "This contains your user settings."
    echo ""
    echo -n "Remove config directory? [y/N]: "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf ~/.kpenv
        echo -e "${GREEN}✓${NC} Removed ~/.kpenv"
    else
        echo -e "${YELLOW}⚠${NC} Keeping ~/.kpenv"
    fi
else
    echo "No config directory found"
fi

echo ""
echo -e "${GREEN}✅ Uninstall complete${NC}"
echo ""
echo "Note: Project-specific .kpenv.json files in your projects were not removed."
echo "You can manually delete them if needed."

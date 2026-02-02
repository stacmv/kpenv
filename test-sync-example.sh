#!/bin/bash
# Manual test script for sync-example improvements
# Tests: Comment hints display and backup prompt

set -e

# Get the absolute path to kpenv in the project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KPENV_PATH="$SCRIPT_DIR/kpenv"

if [ ! -f "$KPENV_PATH" ]; then
    echo "Error: kpenv not found at $KPENV_PATH"
    exit 1
fi

echo "=== Manual Test for sync-example improvements ==="
echo ""
echo "Using kpenv from: $KPENV_PATH"
echo ""

# Create test directory
TEST_DIR="/tmp/kpenv-test-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "✓ Created test directory: $TEST_DIR"
echo ""

# Initialize git (needed for project detection)
git init -q
git remote add origin https://github.com/test/test-project.git

echo "✓ Initialized git repo"
echo ""

# Create .env.example with various comment types
cat > .env.example <<'EOF'
# Database Configuration
# Use localhost for local development
DATABASE_HOST=localhost

DATABASE_PORT=5432 # PostgreSQL default port

# Application Settings
APP_NAME="Test App" # Your application name

DEBUG=false # Enable debug mode

# Redis Configuration
REDIS_HOST=127.0.0.1
REDIS_PORT=6379 # Redis default port
REDIS_DB=0

# API Keys (get from admin)
API_KEY=

# Special case: hash in value
TAG=#v1.0
EOF

echo "✓ Created .env.example with various comment types:"
echo "  - Standalone comments before variables"
echo "  - Inline comments after values"
echo "  - Mixed quoted/unquoted values"
echo ""

# Create minimal .kpenv.json
cat > .kpenv.json <<'EOF'
{
  "project_name": "test-project",
  "example_file": ".env.example"
}
EOF

echo "✓ Created .kpenv.json"
echo ""

echo "=== Expected Behavior ==="
echo ""
echo "1. COMMENT HINTS:"
echo "   When prompted for DATABASE_HOST, you should see:"
echo "     # Database Configuration"
echo "     # Use localhost for local development"
echo ""
echo "   When prompted for DATABASE_PORT, you should see:"
echo "     # PostgreSQL default port"
echo ""
echo "   When prompted for APP_NAME, you should see:"
echo "     # Application Settings"
echo "     # Your application name"
echo ""
echo "2. BACKUP PROMPT:"
echo "   After adding keys, you should see:"
echo "     Would you like to backup .env to KeePass now? [Y/n]:"
echo ""
echo "=== Running kpenv sync-example ==="
echo ""
echo "Using kpenv from project directory: $KPENV_PATH"
echo ""
echo "Press Enter to continue..."
read

# Run sync-example using kpenv from project directory
# Note: This will prompt for values - just press Enter to use defaults
"$KPENV_PATH" sync-example

echo ""
echo "=== Verification ==="
echo ""

if [ -f .env ]; then
    echo "✓ .env file was created"
    echo ""
    echo "Contents of .env:"
    cat .env
    echo ""
else
    echo "✗ .env file was NOT created"
    exit 1
fi

echo ""
echo "=== Test Questions ==="
echo ""
echo "1. Did you see comment hints before each prompt? (Y/n)"
read answer1
if [ "$answer1" != "Y" ] && [ "$answer1" != "y" ] && [ "$answer1" != "" ]; then
    echo "✗ Comment hints NOT displayed correctly"
    FAILED=1
else
    echo "✓ Comment hints displayed"
fi

echo ""
echo "2. Did you see the backup prompt after sync? (Y/n)"
read answer2
if [ "$answer2" != "Y" ] && [ "$answer2" != "y" ] && [ "$answer2" != "" ]; then
    echo "✗ Backup prompt NOT displayed"
    FAILED=1
else
    echo "✓ Backup prompt displayed"
fi

echo ""
echo "3. If you chose Y for backup, did it work or show appropriate error? (Y/n/skipped)"
read answer3

echo ""
if [ -n "$FAILED" ]; then
    echo "=== TEST FAILED ==="
    echo "Some checks did not pass. Please review the output above."
else
    echo "=== TEST PASSED ==="
    echo "All manual checks completed successfully!"
fi

echo ""
echo "Test directory: $TEST_DIR"
echo "You can inspect files manually if needed."
echo "Delete test directory with: rm -rf $TEST_DIR"

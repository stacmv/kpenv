# kpenv Distribution Strategy

**Date:** 2025-11-12
**Version:** 1.0
**Status:** Proposed

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current State Analysis](#current-state-analysis)
3. [Distribution Goals](#distribution-goals)
4. [Proposed Solutions](#proposed-solutions)
5. [Implementation Plan](#implementation-plan)
6. [User Scenarios](#user-scenarios)
7. [Technical Specifications](#technical-specifications)

---

## Executive Summary

This document outlines a comprehensive distribution strategy for **kpenv** (KeePass Environment Manager) to make it easily installable and accessible across different platforms and use cases.

### Key Objectives

- ✅ Global system installation (like `apt install` or `npm -g install`)
- ✅ Automatic PATH configuration
- ✅ Per-project initialization with `kpenv init`
- ✅ Zero-configuration for common use cases
- ✅ Multiple installation methods (apt, composer, manual, script)

---

## Current State Analysis

### What Works

- ✅ Solid core functionality (sync, backup, restore)
- ✅ PHP 8.2+ as a stable foundation
- ✅ Single executable file (easy to distribute)
- ✅ composer.json exists

### Current Limitations

- ❌ **Manual installation** - Users must `chmod +x` and `ln -s` manually
- ❌ **Hardcoded configuration** - Paths hardcoded in script (lines 16-19)
- ❌ **No `init` command** - No guided project setup
- ❌ **No package distribution** - Not available via package managers
- ❌ **No .gitignore check** - Doesn't verify `.env` is gitignored

---

## Distribution Goals

### Primary Goals

1. **Easy Installation**
   - One command to install system-wide
   - Automatic PATH configuration
   - Dependency checking and validation

2. **Flexible Configuration**
   - User-level config file (`~/.kpenv/config`)
   - Project-level config (`.kpenv.json`)
   - Environment variable overrides
   - Sensible defaults

3. **Intuitive Initialization**
   - `kpenv init` to set up new projects
   - Auto-detect example files (`.env.example`, `env.example`, etc.)
   - Check and update `.gitignore`
   - Interactive setup wizard

4. **Multiple Distribution Channels**
   - Manual installation script
   - Composer global install
   - APT repository (Debian/Ubuntu)
   - Homebrew (macOS)
   - Direct download

---

## Proposed Solutions

### Solution 1: Installation Script (Recommended for v1.1)

**Description:** Bash script that installs kpenv system-wide

**File:** `install.sh`

```bash
#!/bin/bash
# Downloads and installs kpenv to /usr/local/bin
# Creates ~/.kpenv/config with defaults
# Validates dependencies (PHP 8.2+, keepassxc-cli)
```

**Installation:**
```bash
curl -sSL https://raw.githubusercontent.com/user/kpenv/main/install.sh | bash
# OR
wget -qO- https://raw.githubusercontent.com/user/kpenv/main/install.sh | bash
```

**Advantages:**
- ✅ Simple one-liner installation
- ✅ Cross-platform (Linux, macOS, WSL)
- ✅ Validates dependencies
- ✅ Sets up configuration automatically

**Implementation Time:** 2-4 hours

---

### Solution 2: Composer Global Install

**Description:** Publish to Packagist as a global Composer package

**Installation:**
```bash
composer global require stacmv/kpenv
```

**Requirements:**
- Update `composer.json` with proper package name
- Register on Packagist.org
- Add installation instructions
- Ensure `bin` is properly configured

**Advantages:**
- ✅ Familiar to PHP developers
- ✅ Automatic PATH handling (if Composer in PATH)
- ✅ Version management
- ✅ Easy updates (`composer global update`)

**Implementation Time:** 1-2 hours

---

### Solution 3: APT Repository (Future v2.0)

**Description:** Debian package repository for apt-based systems

**Installation:**
```bash
sudo add-apt-repository ppa:stacmv/kpenv
sudo apt update
sudo apt install kpenv
```

**Requirements:**
- Create `.deb` package
- Set up PPA or custom repository
- Package dependencies (php8.2-cli, keepassxc)
- Maintainer scripts (postinst, prerm)

**Advantages:**
- ✅ Native package management
- ✅ Automatic dependency installation
- ✅ System-wide availability
- ✅ Familiar to Ubuntu/Debian users

**Implementation Time:** 8-16 hours (including testing)

---

### Solution 4: Homebrew Tap (macOS)

**Description:** Homebrew formula for macOS users

**Installation:**
```bash
brew tap stacmv/kpenv
brew install kpenv
```

**Requirements:**
- Create Homebrew formula
- Set up tap repository
- Define dependencies

**Advantages:**
- ✅ Native macOS package management
- ✅ Automatic dependency handling
- ✅ Easy updates

**Implementation Time:** 4-6 hours

---

### Solution 5: Manual Installation (Already Works)

**Description:** Direct download and manual setup

**Current Process:**
```bash
git clone https://github.com/user/kpenv.git
cd kpenv
chmod +x kpenv
sudo ln -s $(pwd)/kpenv /usr/local/bin/kpenv
```

**Improvements Needed:**
- Add `make install` target
- Add uninstall script
- Better documentation

---

## Implementation Plan

### Phase 1: Foundation (v1.1) - Priority: HIGH

#### 1.1 Configuration System

**Create:** `~/.kpenv/config` (YAML or JSON)

```yaml
# ~/.kpenv/config
base_dev_folder: /home/username/dev
keepass_db: /home/username/Documents/work-secrets.kdbx
default_env: development
example_files:
  - .env.example
  - env.example
  - .env.dist
```

**Create:** `.kpenv.json` (project-level config)

```json
{
  "project_name": "my-project",
  "keepass_entry_path": "projects/my-project",
  "example_file": ".env.example",
  "environments": ["development", "staging", "production"]
}
```

**Implementation:**
- Add config file reading logic to `kpenv`
- Use hierarchy: CLI flags > Project config > User config > Defaults
- Auto-create `~/.kpenv/config` on first run

---

#### 1.2 Add `kpenv init` Command

**Purpose:** Initialize kpenv in a project directory

**Workflow:**
```bash
cd /path/to/project
kpenv init

# Interactive prompts:
# 1. Detect or ask for KeePass database path
# 2. Auto-detect project name (from directory)
# 3. Find .env.example (or ask which file to use)
# 4. Check if .env exists
# 5. Check if .env is in .gitignore (add if not)
# 6. Create .kpenv.json config
# 7. Optionally run sync-example
```

**Features:**
- ✅ Auto-detect `.env.example`, `env.example`, `.env.dist`
- ✅ Check `.gitignore` and add `.env` if missing
- ✅ Create `.kpenv.json` with project settings
- ✅ Validate KeePassXC installation
- ✅ Offer to run `sync-example` immediately

**Code Location:** New function `init_project()` in `kpenv`

---

#### 1.3 Installation Script

**Create:** `install.sh`

```bash
#!/bin/bash
set -e

echo "Installing kpenv..."

# 1. Check dependencies
command -v php >/dev/null 2>&1 || { echo "PHP 8.2+ required"; exit 1; }
command -v keepassxc-cli >/dev/null 2>&1 || { echo "KeePassXC required"; exit 1; }

# 2. Check PHP version
php_version=$(php -r 'echo PHP_VERSION;')
required_version="8.2.0"
if [ "$(printf '%s\n' "$required_version" "$php_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "Error: PHP 8.2+ required (found $php_version)"
    exit 1
fi

# 3. Download or copy kpenv
if [ -f "./kpenv" ]; then
    # Local installation
    sudo cp kpenv /usr/local/bin/kpenv
else
    # Remote installation
    curl -sSL https://raw.githubusercontent.com/user/kpenv/main/kpenv -o /tmp/kpenv
    sudo mv /tmp/kpenv /usr/local/bin/kpenv
fi

# 4. Make executable
sudo chmod +x /usr/local/bin/kpenv

# 5. Create config directory
mkdir -p ~/.kpenv

# 6. Create default config if not exists
if [ ! -f ~/.kpenv/config ]; then
    cat > ~/.kpenv/config <<EOF
base_dev_folder: $HOME/dev
keepass_db: $HOME/Documents/work-secrets.kdbx
default_env: development
example_files:
  - .env.example
  - env.example
  - .env.dist
EOF
    echo "Created default config at ~/.kpenv/config"
fi

echo "✓ kpenv installed successfully!"
echo "Run 'kpenv init' in your project directory to get started."
```

**Usage:**
```bash
# Local installation
cd kpenv
./install.sh

# Remote installation
curl -sSL https://raw.githubusercontent.com/user/kpenv/main/install.sh | bash
```

---

#### 1.4 Uninstall Script

**Create:** `uninstall.sh`

```bash
#!/bin/bash
set -e

echo "Uninstalling kpenv..."

# Remove binary
sudo rm -f /usr/local/bin/kpenv

# Ask about config
read -p "Remove config directory (~/.kpenv)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ~/.kpenv
    echo "✓ Config removed"
fi

echo "✓ kpenv uninstalled"
```

---

### Phase 2: Package Management (v1.2) - Priority: MEDIUM

#### 2.1 Composer Package

**Update:** `composer.json`

```json
{
  "name": "stacmv/kpenv",
  "description": "KeePass-based environment file manager for secure development workflows",
  "type": "library",
  "license": "MIT",
  "version": "1.1.0",
  "authors": [
    {
      "name": "stacmv",
      "email": "stacmv@example.com"
    }
  ],
  "require": {
    "php": ">=8.2"
  },
  "bin": ["kpenv"],
  "keywords": ["keepass", "environment", "dotenv", "secrets", "security", "cli"]
}
```

**Steps:**
1. Register on Packagist.org
2. Connect GitHub repository
3. Tag releases properly
4. Update README with Composer install instructions

**Installation:**
```bash
composer global require stacmv/kpenv
```

---

### Phase 3: Native Packages (v2.0) - Priority: LOW

#### 3.1 Debian/Ubuntu APT Package

**Create:** `debian/` directory structure
- `control` - Package metadata
- `postinst` - Post-installation script
- `prerm` - Pre-removal script
- `changelog` - Version history

**Build:**
```bash
dpkg-deb --build kpenv_1.0.0_all.deb
```

#### 3.2 Homebrew Formula

**Create:** `Formula/kpenv.rb`

```ruby
class Kpenv < Formula
  desc "KeePass-based environment file manager"
  homepage "https://github.com/stacmv/kpenv"
  url "https://github.com/stacmv/kpenv/archive/v1.0.0.tar.gz"
  sha256 "..."
  license "MIT"

  depends_on "php@8.2"
  depends_on "keepassxc"

  def install
    bin.install "kpenv"
  end

  test do
    system "#{bin}/kpenv", "--help"
  end
end
```

---

## User Scenarios

### Scenario 1: First-Time Global Installation

**User:** Developer installing kpenv for the first time

**Steps:**
```bash
# Option A: Installation script (recommended)
curl -sSL https://raw.githubusercontent.com/stacmv/kpenv/main/install.sh | bash

# Option B: Composer
composer global require stacmv/kpenv

# Option C: Manual
git clone https://github.com/stacmv/kpenv.git
cd kpenv
sudo ./install.sh
```

**Result:**
- ✅ `kpenv` available globally in PATH
- ✅ `~/.kpenv/config` created with defaults
- ✅ Dependencies validated
- ✅ Ready to use in any project

---

### Scenario 2: Initialize New Project

**User:** Starting a new project with environment files

**Steps:**
```bash
cd ~/dev/my-new-project
kpenv init
```

**Interactive Flow:**
```
🔧 Initializing kpenv in current project...

Project detected: my-new-project
Current directory: /home/user/dev/my-new-project

✓ Found .env.example
✓ .env does not exist (will be created)
✓ KeePass database: /home/user/Documents/work-secrets.kdbx

Checking .gitignore...
⚠ .env not found in .gitignore

Add .env to .gitignore? [Y/n]: y
✓ Added .env to .gitignore

Create .kpenv.json config? [Y/n]: y
✓ Created .kpenv.json

Sync .env.example to .env now? [Y/n]: y

Syncing .env.example with .env...
New key 'DATABASE_HOST' found. Enter value: localhost
New key 'DATABASE_PASSWORD' found. Enter value: ********
New key 'API_KEY' found. Enter value: test_key_123

✓ Sync completed. 3 keys added to .env

✅ Project initialized successfully!

Next steps:
  1. Edit .env with your values
  2. Run 'kpenv backup-env' to save to KeePass
  3. Share KeePass database with your team
```

**Result:**
- ✅ `.gitignore` updated with `.env`
- ✅ `.kpenv.json` created
- ✅ `.env` created from `.env.example`
- ✅ Ready to backup to KeePass

---

### Scenario 3: Clone Existing Project

**User:** Developer cloning a team project that uses kpenv

**Steps:**
```bash
git clone https://github.com/team/project.git
cd project
kpenv restore-env
```

**Interactive Flow:**
```
🔐 Restoring environment from KeePass...

Project: project
Environment: development
KeePass entry: project/development

KeePass database password: ********

✓ Retrieved environment from KeePass
✓ Created .env successfully!

✅ Environment restored!

Your project is ready to run.
```

**Result:**
- ✅ `.env` file restored from KeePass
- ✅ No manual copy-pasting needed
- ✅ Secure password entry
- ✅ Ready to develop immediately

---

### Scenario 4: Calling kpenv from Any Location

**User:** Working on multiple projects

**Example:**
```bash
# From anywhere in the system
cd ~/dev/project-a
kpenv backup-env

cd ~/dev/project-b
kpenv restore-env

cd ~/Desktop/client-work/project-c
kpenv init

# kpenv is always available via PATH
which kpenv
# Output: /usr/local/bin/kpenv
```

**Result:**
- ✅ `kpenv` works from any directory
- ✅ Automatically detects project context
- ✅ No need to specify full paths

---

## Technical Specifications

### Configuration Priority

**Hierarchy (highest to lowest):**

1. **CLI Arguments** - `--env=production --password=xxx`
2. **Environment Variables** - `KEEPASS_PASSWORD`, `KPENV_DB`
3. **Project Config** - `.kpenv.json` in current directory
4. **User Config** - `~/.kpenv/config`
5. **Defaults** - Hardcoded in script

### File Locations

```
System:
  /usr/local/bin/kpenv                 # Main executable

User:
  ~/.kpenv/
    ├── config                         # User configuration
    └── cache/                         # Future: cached data

Project:
  .kpenv.json                          # Project configuration
  .env                                 # Environment file (gitignored)
  .env.example                         # Example file (committed)
  .env.staging                         # Optional: staging env
  .env.production                      # Optional: production env
```

### Config File Format

**User Config:** `~/.kpenv/config` (YAML)

```yaml
# KeePass database path
keepass_db: /home/user/Documents/work-secrets.kdbx

# Base folder for project detection
base_dev_folder: /home/user/dev

# Default environment name
default_env: development

# Example file detection order
example_files:
  - .env.example
  - env.example
  - .env.dist
  - example.env

# Automatically add .env to .gitignore if missing
auto_gitignore: true
```

**Project Config:** `.kpenv.json` (JSON)

```json
{
  "project_name": "my-awesome-app",
  "keepass_entry_path": "projects/my-awesome-app",
  "example_file": ".env.example",
  "environments": [
    "development",
    "staging",
    "production"
  ]
}
```

### Dependencies

**Required:**
- PHP 8.2+
- KeePassXC with CLI (`keepassxc-cli`)

**Optional:**
- Composer (for Composer installation method)
- Git (for .gitignore management)

---

## Recommended Implementation Order

### Immediate (v1.1) - This Week

1. ✅ **Add `init` command** - 2-3 hours
   - Detect example files
   - Check/update .gitignore
   - Create .kpenv.json
   - Interactive setup

2. ✅ **Configuration system** - 2-3 hours
   - Read `~/.kpenv/config`
   - Read `.kpenv.json`
   - Config hierarchy

3. ✅ **Installation script** - 1-2 hours
   - `install.sh` for easy setup
   - Dependency validation
   - Auto-config creation

4. ✅ **Update documentation** - 1 hour
   - Installation instructions
   - `init` command docs
   - Configuration guide

**Total Time:** ~8 hours

---

### Short-term (v1.2) - Next 2 Weeks

5. ✅ **Composer package** - 1-2 hours
   - Publish to Packagist
   - Test global install
   - Update docs

6. ✅ **Makefile** - 30 minutes
   - `make install`
   - `make uninstall`
   - `make test`

**Total Time:** ~2 hours

---

### Long-term (v2.0) - Future

7. ⏳ **APT Package** - 8-16 hours
8. ⏳ **Homebrew Formula** - 4-6 hours
9. ⏳ **Windows support** - TBD
10. ⏳ **Auto-update mechanism** - TBD

---

## Success Metrics

### Installation Success

- ✅ User can install with single command
- ✅ `kpenv` available in PATH immediately
- ✅ No manual configuration needed for basic use
- ✅ Works on Linux and macOS

### Usability Success

- ✅ `kpenv init` completes project setup in <1 minute
- ✅ .gitignore automatically updated
- ✅ Example files detected automatically
- ✅ Clear error messages for common issues

### Distribution Success

- ✅ Available via 3+ installation methods
- ✅ Documentation covers all scenarios
- ✅ Uninstall is as easy as install

---

## Questions & Decisions

### Q1: Which installation method to prioritize?

**Recommendation:** Installation script (curl/wget)

**Rationale:**
- ✅ Fastest to implement
- ✅ Works universally (Linux, macOS, WSL)
- ✅ Familiar pattern (similar to Homebrew, rustup, etc.)
- ✅ Can be automated in CI/CD
- ✅ No dependencies beyond PHP and KeePassXC

---

### Q2: Config format - YAML or JSON?

**Recommendation:** YAML for user config, JSON for project config

**Rationale:**
- ✅ YAML more human-friendly for `~/.kpenv/config` (edited manually)
- ✅ JSON for `.kpenv.json` (can be generated, IDE support)
- ✅ Both widely supported in PHP

**Alternative:** JSON for both (simpler implementation)

---

### Q3: Should `kpenv init` auto-run sync-example?

**Recommendation:** Ask user (optional prompt)

**Rationale:**
- ✅ Gives user control
- ✅ Allows review of .env.example first
- ✅ Can be skipped if .env already exists
- ✅ Default to "yes" for convenience

---

### Q4: How to handle project name detection?

**Current:** Relies on `$baseDevFolder` prefix

**Recommendation:** Multiple detection methods (fallback chain)

1. `.kpenv.json` `project_name` field (explicit)
2. Git remote URL (parse repo name)
3. Directory name (relative to base folder)
4. Current directory name (fallback)
5. Prompt user (last resort)

---

## Conclusion

### Summary

This distribution strategy provides a clear path to making kpenv easily installable and usable across different platforms and workflows. The phased approach allows incremental improvements while delivering immediate value.

### Next Steps

1. Review and approve this strategy
2. Implement Phase 1 (v1.1) features
3. Test installation scripts on multiple platforms
4. Update documentation
5. Release v1.1 with new features
6. Gather user feedback
7. Iterate on Phase 2 features

### Estimated Timeline

- **Phase 1 (v1.1):** 1 week
- **Phase 2 (v1.2):** 2 weeks
- **Phase 3 (v2.0):** 1-2 months

---

**Document Status:** ✅ Ready for Review
**Author:** Claude + Human collaboration
**Date:** 2025-11-12

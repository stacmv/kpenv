# kpenv - KeePass Environment Manager

**Version:** 1.1.0
**License:** MIT
**Author:** Human + Claude collaboration

---

## Overview

**kpenv** is a command-line tool for managing `.env` files using KeePassXC as a secure backend. It allows you to:

- 🔄 Sync `.env.example` to `.env` with interactive prompts
- 💾 Backup `.env` files to KeePass entry notes
- 📥 Restore `.env` files from KeePass
- 🔐 Secure storage without committing secrets to git
- 🌍 Multi-environment support (development, staging, production)

**Perfect for:**
- Teams sharing environment configurations securely
- Developers working across multiple machines
- Projects with complex environment setups
- Avoiding secrets in version control

---

## Features

✅ **Easy Installation** - One-command installation script
✅ **Project Initialization** - `kpenv init` sets up projects automatically
✅ **Auto .gitignore** - Ensures `.env` files are never committed
✅ **Flexible Configuration** - User and project-level JSON configs
✅ **Sync from Example** - Interactively create `.env` from example files
✅ **Backup to KeePass** - Store environment files in KeePass database notes
✅ **Restore from KeePass** - Retrieve environment files on new machines
✅ **Auto Project Detection** - Smart project name detection from git/path
✅ **Multi-Environment** - Support for development, staging, production
✅ **Secure** - Password never stored, read from stdin or env var
✅ **Safe Restore** - Creates `.env.fetched` if local `.env` exists

---

## Requirements

- **PHP 8.2+** (uses `declare(strict_types=1)`, `str_starts_with`)
- **KeePassXC** with CLI tool (`keepassxc-cli`)
- **KeePass database** file (`.kdbx`)

### Installation

#### Quick Install (Recommended)

**Linux/macOS:**

```bash
# Clone or download the repository
git clone https://github.com/stacmv/env-manager.git
cd env-manager

# Run installer
./install.sh
```

The installer will:
- ✅ Check PHP 8.2+ is installed
- ✅ Check for KeePassXC CLI
- ✅ Install `kpenv` to `/usr/local/bin`
- ✅ Create `~/.kpenv/config.json` with defaults
- ✅ Make kpenv globally available

**Windows:**

```powershell
# Prerequisites: Install Scoop package manager first
# Visit https://scoop.sh or run:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# Clone or download the repository
git clone https://github.com/stacmv/env-manager.git
cd env-manager

# Run installer
.\install.ps1
```

The Windows installer will:
- ✅ Check Scoop is installed (required for dependency management)
- ✅ Offer to install PHP 8.2+ via Scoop if not found
- ✅ Offer to install KeePassXC via Scoop if not found
- ✅ Offer to install Cmder (Unix-like shell) via Scoop if no bash found
- ✅ Install `kpenv` to user directory with PATH access
- ✅ Create `%USERPROFILE%\.kpenv\config.json` with defaults
- ✅ Make kpenv globally available

**Note for Windows users:** kpenv works best in Unix-like environments (Git Bash, MSYS2, WSL, Cmder). The installer can optionally install Cmder for you.

#### Manual Installation

```bash
# 1. Install dependencies
# Ubuntu/Debian
sudo apt install php-cli keepassxc

# macOS
brew install php keepassxc

# 2. Copy kpenv to PATH
sudo cp kpenv /usr/local/bin/kpenv
sudo chmod +x /usr/local/bin/kpenv

# 3. Create config directory
mkdir -p ~/.kpenv

# 4. Create default config
cat > ~/.kpenv/config.json <<EOF
{
  "base_dev_folder": "$HOME/dev",
  "keepass_db": "$HOME/Documents/work-secrets.kdbx",
  "default_env": "development",
  "example_files": [".env.example", "env.example", ".env.dist"],
  "auto_gitignore": true
}
EOF
```

#### Uninstallation

**Linux/macOS:**
```bash
./uninstall.sh
```

**Windows:**
```powershell
.\uninstall.ps1
```

### Shell Completion

The installer automatically sets up shell completions. For manual setup:

#### Bash

```bash
# System-wide (requires sudo)
sudo cp completions/kpenv.bash /etc/bash_completion.d/kpenv

# Or user-local
mkdir -p ~/.local/share/bash-completion/completions
cp completions/kpenv.bash ~/.local/share/bash-completion/completions/kpenv

# Reload completions
source ~/.bashrc
```

#### Zsh

```bash
# Copy completion file
mkdir -p ~/.zsh/completions
cp completions/_kpenv ~/.zsh/completions/_kpenv

# Add to ~/.zshrc (if not already present)
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit

# Reload
source ~/.zshrc
```

#### Usage

After installation, use Tab to complete:

```bash
kpenv <Tab>              # Shows: init sync-example backup-env restore-env help
kpenv backup-env --<Tab> # Shows: --env --password
kpenv backup-env --env=<Tab>  # Shows: development staging production
```

---

## Usage

### Commands

#### 0. Initialize Project (New!)

Set up kpenv in your project directory:

```bash
kpenv init
```

This command will:
- ✅ Detect your project name from git or directory
- ✅ Find `.env.example` or other example files
- ✅ Check if `.env` is in `.gitignore` (and add it if not)
- ✅ Create `.kpenv.json` project configuration
- ✅ Optionally sync `.env.example` to `.env`

**Example:**
```
$ cd my-project
$ kpenv init

🔧 Initializing kpenv in current project...

Project detected: my-project
Current directory: /home/user/dev/my-project

✓ Found .env.example
✓ .env does not exist (will be created)
✓ KeePass database: /home/user/Documents/work-secrets.kdbx
✓ keepassxc-cli found

Checking .gitignore...
⚠ .env not found in .gitignore

Add .env to .gitignore? [Y/n]: y
✓ Added .env to .gitignore

Create .kpenv.json config? [Y/n]: y
✓ Created .kpenv.json

Sync .env.example to .env now? [Y/n]: y

✅ Project initialized successfully!
```

#### 1. Sync from Example

Create or update `.env` from `.env.example` with interactive prompts:

```bash
kpenv sync-example

# With specific environment
kpenv sync-example --env=staging
```

**Example:**
```
$ kpenv sync-example
Syncing .env.example with local .env...
New key 'DATABASE_HOST' found. Enter value: localhost
New key 'DATABASE_PASSWORD' found. Enter value: ********
Sync completed. 2 keys added to .env.
```

#### 2. Backup to KeePass

Backup your `.env` file to KeePass:

```bash
kpenv backup-env

# With password from environment variable
KEEPASS_PASSWORD=mypass kpenv backup-env

# With specific environment
kpenv backup-env --env=production
```

**What happens:**
- Reads `.env` file
- Stores content in KeePass entry notes at path: `{project-name}/{environment}`
- Creates KeePass groups if needed

#### 3. Restore from KeePass

Restore `.env` file from KeePass on a new machine:

```bash
kpenv restore-env

# With password as argument (less secure)
kpenv restore-env --password=mypass

# Specific environment
kpenv restore-env --env=staging
```

**What happens:**
- Retrieves content from KeePass entry: `{project-name}/{environment}`
- Creates `.env` file
- If `.env` exists, creates `.env.fetched` instead (safe mode)

---

## Configuration

kpenv uses a hierarchical configuration system:

**Priority (highest to lowest):**
1. CLI arguments (`--env=production`)
2. Environment variables (`KPENV_DB`, `KPENV_BASE_FOLDER`)
3. Project config (`.kpenv.json`)
4. User config (`~/.kpenv/config.json`)
5. Defaults

### User Configuration

Location: `~/.kpenv/config.json`

```json
{
  "base_dev_folder": "/home/username/dev",
  "keepass_db": "/home/username/Documents/work-secrets.kdbx",
  "default_env": "development",
  "example_files": [
    ".env.example",
    "env.example",
    ".env.dist",
    "example.env"
  ],
  "auto_gitignore": true
}
```

**Options:**
- `base_dev_folder` - Base directory for project detection
- `keepass_db` - Path to KeePass database file
- `default_env` - Default environment name (development, staging, production)
- `example_files` - List of example file names to search for (in order)
- `auto_gitignore` - Automatically add `.env` to `.gitignore` during init

### Project Configuration

Location: `.kpenv.json` (in project root)

Created automatically by `kpenv init`, or create manually:

```json
{
  "project_name": "my-awesome-app",
  "example_file": ".env.example",
  "environments": [
    "development",
    "staging",
    "production"
  ]
}
```

**Options:**
- `project_name` - Explicit project name (overrides auto-detection)
- `example_file` - Specific example file to use
- `environments` - List of available environments

### Environment Variables

Override configuration on-the-fly:

```bash
# Override KeePass database path
KPENV_DB=/path/to/other.kdbx kpenv backup-env

# Override base folder
KPENV_BASE_FOLDER=/home/user/projects kpenv sync-example

# Pass KeePass password (non-interactive)
KEEPASS_PASSWORD=mypassword kpenv restore-env
```

---

## Workflow Examples

### Initial Setup (Developer A)

```bash
# 1. Initialize project
kpenv init
# This will guide you through setup

# 2. Backup to KeePass
kpenv backup-env
# Enter KeePass password when prompted
```

### Setup on New Machine (Developer B)

```bash
# 1. Clone the project
git clone https://github.com/username/project.git
cd project

# 2. Restore .env from KeePass
kpenv restore-env
# Enter KeePass password when prompted

# 3. Ready to work!
```

### Multi-Environment Workflow

```bash
# Development environment
kpenv backup-env --env=development

# Staging environment
kpenv backup-env --env=staging

# Production environment
kpenv backup-env --env=production

# Restore specific environment
kpenv restore-env --env=production
```

---

## Project Structure

```
env-manager/
├── kpenv                          # Main executable
├── install.sh                     # Installation script (Linux/macOS)
├── install.ps1                    # Installation script (Windows)
├── uninstall.sh                   # Uninstallation script (Linux/macOS)
├── uninstall.ps1                  # Uninstallation script (Windows)
├── README.md                      # This file
├── LICENSE                        # MIT License
├── DISTRIBUTION_STRATEGY.md       # Distribution plan
├── composer.json                  # PHP package metadata
├── completions/
│   ├── kpenv.bash                # Bash completion script
│   └── _kpenv                    # Zsh completion script
├── docs/
│   ├── prd.md                    # Product Requirements Document
│   └── planning/                 # Planning Framework
│       ├── FRAMEWORK.md
│       ├── implementation-plan.md
│       ├── session-log.md
│       └── decisions.md
├── examples/
│   └── .env.example              # Example environment file
└── tests/                        # Future: PHPUnit tests
```

### User Files (created on install)

```
~/.kpenv/
└── config.json                    # User configuration

your-project/
└── .kpenv.json                    # Project configuration (created by init)
```

---

## How It Works

### KeePass Storage Structure

Environment files are stored in KeePass as entry notes:

```
KeePass Database
└── my-project/
    ├── development (entry)
    │   └── Notes: [.env content]
    ├── staging (entry)
    │   └── Notes: [.env.staging content]
    └── production (entry)
        └── Notes: [.env.production content]
```

### Project Name Detection

The tool automatically detects your project name from the directory path:

```
Current directory: /home/username/dev/my-awesome-project/
Project name: my-awesome-project
KeePass entry: my-awesome-project/development
```

---

## Security Considerations

✅ **Password Handling**
- Never stored in code or config
- Read from stdin (hidden input) or `KEEPASS_PASSWORD` env var
- Passed to `keepassxc-cli` via stdin

✅ **KeePass Database**
- Encrypted with master password
- Supports key files and hardware keys (via KeePassXC)

✅ **Safe Restore**
- Won't overwrite existing `.env` files
- Creates `.env.fetched` for manual review

⚠️ **Best Practices**
- Don't commit `.env` files to git (add to `.gitignore`)
- Use strong KeePass master password
- Regularly backup your KeePass database
- Limit access to KeePass database file

---

## Troubleshooting

### "KeePassXC-CLI executable not found"

```bash
# Check if installed
which keepassxc-cli

# Install KeePassXC (includes CLI)
# See Installation section above
```

### "KeePass database not found"

```bash
# Verify database path in kpenv configuration
# Default: ~/Documents/work-secrets.kdbx

# Create a new database if needed (via KeePassXC GUI)
```

### "Entry not found or password incorrect"

- Verify KeePass password is correct
- Check that backup was successful
- Verify project name matches (check `./kpenv backup-env` output)

### "Error: Could not determine project name"

The tool requires your project to be under the configured `$baseDevFolder`:

```php
// In kpenv
$baseDevFolder = "/home/username/dev";

// Your project must be at:
// /home/username/dev/{project-name}/
```

---

## Roadmap

### Version 1.0 (Complete ✅)
- [x] Core sync/backup/restore functionality
- [x] Multi-environment support
- [x] Interactive prompts
- [x] Safe restore mode
- [x] Auto project detection

### Version 1.1 (Current - Complete ✅)
- [x] Installation script (`install.sh`)
- [x] Configuration system (JSON-based)
- [x] `kpenv init` command
- [x] Auto .gitignore management
- [x] Smart project name detection
- [x] Global PATH installation

### Version 1.2 (Planned)
- [ ] List all backed-up projects (`list` command)
- [ ] Diff local vs KeePass (`diff` command)
- [ ] PHPUnit test suite
- [ ] CI/CD integration
- [ ] Composer package distribution

### Version 2.0 (Future)
- [ ] Refactor to PSR-4 classes
- [ ] APT/Homebrew packages
- [ ] Plugin system for other backends (1Password, Bitwarden)
- [ ] GUI wrapper (Electron/Tauri)

---

## Contributing

This project uses the **Planning Framework** for structured development. See `/docs/planning/FRAMEWORK.md` for details.

### Development Setup

```bash
# 1. Clone/copy to your dev environment
# 2. Review planning documents
cat docs/planning/implementation-plan.md
cat docs/planning/session-log.md

# 3. Make changes
# 4. Update planning docs
# 5. Run tests (when implemented)
# 6. Submit PR
```

---

## License

MIT License - see [LICENSE](LICENSE) file

---

## Credits

Created by Human + Claude collaboration as part of the VAT Event Classifier project.

Extracted to standalone tool: 2025-11-05

---

## Links

- **Planning Framework:** `/docs/planning/FRAMEWORK.md`
- **PRD:** `/docs/prd.md`
- **Session Log:** `/docs/planning/session-log.md`
- **KeePassXC:** https://keepassxc.org/
- **KeePassXC CLI Docs:** https://keepassxc.org/docs/KeePassXC_UserGuide.html#_command_line_interface

---

**Made with ❤️ and AI assistance**

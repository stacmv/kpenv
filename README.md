# kpenv - KeePass Environment Manager

**Version:** 1.0.0
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

✅ **Sync from Example** - Interactively create `.env` from `.env.example`
✅ **Backup to KeePass** - Store environment files in KeePass database notes
✅ **Restore from KeePass** - Retrieve environment files on new machines
✅ **Auto Project Detection** - Detects project name from directory path
✅ **Multi-Environment** - Support for `.env`, `.env.staging`, `.env.production`
✅ **Secure** - Password never stored, read from stdin or env var
✅ **Safe Restore** - Creates `.env.fetched` if local `.env` exists

---

## Requirements

- **PHP 8.2+** (uses `declare(strict_types=1)`, `str_starts_with`)
- **KeePassXC** with CLI tool (`keepassxc-cli`)
- **KeePass database** file (`.kdbx`)

### Installation

```bash
# Install KeePassXC (includes CLI)
# Ubuntu/Debian
sudo apt install keepassxc

# macOS
brew install keepassxc

# Verify keepassxc-cli is available
which keepassxc-cli

# Make kpenv executable
chmod +x kpenv

# Optional: Add to PATH
ln -s $(pwd)/kpenv /usr/local/bin/kpenv
```

---

## Usage

### Configuration

Edit the configuration at the top of `kpenv`:

```php
$baseDevFolder = "/home/username/dev";  // Your projects folder
$keepassDb = getenv("HOME") . "/Documents/secrets.kdbx";  // KeePass DB path
$defaultEnv = "development";  // Default environment name
```

### Commands

#### 1. Sync from Example

Create or update `.env` from `.env.example` with interactive prompts:

```bash
./kpenv sync-example

# With specific environment
./kpenv sync-example --env=staging
```

**Example:**
```
$ ./kpenv sync-example
Syncing .env.example with local .env...
New key 'DATABASE_HOST' found. Enter value: localhost
New key 'DATABASE_PASSWORD' found. Enter value: ********
Sync completed. 2 keys added to .env.
```

#### 2. Backup to KeePass

Backup your `.env` file to KeePass:

```bash
./kpenv backup-env

# With password from environment variable
KEEPASS_PASSWORD=mypass ./kpenv backup-env

# With specific environment
./kpenv backup-env --env=production
```

**What happens:**
- Reads `.env` file
- Stores content in KeePass entry notes at path: `{project-name}/{environment}`
- Creates KeePass groups if needed

#### 3. Restore from KeePass

Restore `.env` file from KeePass on a new machine:

```bash
./kpenv restore-env

# With password as argument (less secure)
./kpenv restore-env --password=mypass

# Specific environment
./kpenv restore-env --env=staging
```

**What happens:**
- Retrieves content from KeePass entry: `{project-name}/{environment}`
- Creates `.env` file
- If `.env` exists, creates `.env.fetched` instead (safe mode)

---

## Workflow Example

### Initial Setup (Developer A)

```bash
# 1. Create .env from example
./kpenv sync-example
# Interactively fill in values

# 2. Backup to KeePass
./kpenv backup-env
# Enter KeePass password when prompted
```

### Setup on New Machine (Developer B)

```bash
# 1. Clone the project
git clone https://github.com/username/project.git
cd project

# 2. Restore .env from KeePass
./kpenv restore-env
# Enter KeePass password when prompted

# 3. Ready to work!
```

### Multi-Environment Workflow

```bash
# Development environment
./kpenv backup-env --env=development

# Staging environment
./kpenv backup-env --env=staging

# Production environment
./kpenv backup-env --env=production

# Restore specific environment
./kpenv restore-env --env=production
```

---

## Project Structure

```
keepass-env-manager/
├── kpenv                     # Main executable
├── README.md                 # This file
├── LICENSE                   # MIT License
├── composer.json             # PHP package metadata
├── docs/
│   ├── prd.md               # Product Requirements Document
│   └── planning/            # Planning Framework
│       ├── FRAMEWORK.md
│       ├── implementation-plan.md
│       ├── session-log.md
│       └── decisions.md
├── examples/
│   └── .env.example         # Example environment file
└── tests/                   # Future: PHPUnit tests
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

### Version 1.0 (Current - Complete ✅)
- [x] Core sync/backup/restore functionality
- [x] Multi-environment support
- [x] Interactive prompts
- [x] Safe restore mode
- [x] Auto project detection

### Version 1.1 (Planned)
- [ ] List all backed-up projects (`list` command)
- [ ] Diff local vs KeePass (`diff` command)
- [ ] Config file support (`kpenv.json`)
- [ ] PHPUnit test suite
- [ ] CI/CD integration

### Version 2.0 (Future)
- [ ] Refactor to PSR-4 classes
- [ ] Composer package distribution
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

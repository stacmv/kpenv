# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**kpenv** is a CLI tool written in PHP 8.2+ for managing `.env` files using KeePassXC as a secure backend. It enables teams to securely share environment configurations through KeePass without committing secrets to version control.

## Core Architecture

### Single Executable Design

The entire application is contained in a single executable file: `kpenv` (PHP shebang script). This monolithic design choice is intentional for easy distribution and deployment.

**Key classes in `kpenv`:**
- `Config` - Hierarchical configuration management (CLI args > env vars > project config > user config > defaults)
- `KeePassXCService` - KeePass database interaction via `keepassxc-cli`
- `EnvFileManager` - .env file parsing, syncing, and manipulation
- `GitIgnoreManager` - .gitignore file management
- `ProjectDetector` - Auto-detection of project names from git/directory structure

### Configuration Hierarchy

Configuration is resolved in this priority order (highest to lowest):
1. CLI arguments (`--env=production`)
2. Environment variables (`KPENV_DB`, `KPENV_BASE_FOLDER`, `KEEPASS_PASSWORD`)
3. Project config (`.kpenv.json` in project root)
4. User config (`~/.kpenv/config.json`)
5. Defaults (hardcoded in Config class)

**User config location:** `~/.kpenv/config.json`
**Project config location:** `./.kpenv.json`

### KeePass Storage Structure

Environment files are stored as KeePass entry notes in this structure:
```
KeePass Database
└── {project-name}/
    ├── development (entry with .env content in Notes field)
    ├── staging (entry)
    └── production (entry)
```

## Development Commands

### Testing

```bash
# Run all tests with Pest
composer test

# Run tests with coverage
composer test:coverage

# Run tests directly with vendor binary
./vendor/bin/pest

# Run specific test file
./vendor/bin/pest tests/Unit/ParseEnvLineTest.php
```

### Installation (for testing)

```bash
# Linux/macOS installation
./install.sh

# Windows installation
.\install.ps1

# Manual installation
sudo cp kpenv /usr/local/bin/kpenv
sudo chmod +x /usr/local/bin/kpenv
```

### Uninstallation

```bash
# Linux/macOS
./uninstall.sh

# Windows
.\uninstall.ps1
```

## Key Implementation Details

### Project Name Detection

The tool uses this fallback chain to detect project names:
1. Explicit `project_name` in `.kpenv.json`
2. Git remote origin URL parsing
3. Directory name relative to `base_dev_folder` config
4. Current directory basename
5. Manual user input (last resort)

### Security Model

- KeePass password is NEVER stored in files or config
- Password accepted via stdin (interactive) or `KEEPASS_PASSWORD` env var
- All KeePassXC operations use stdin for password input
- Safe restore mode creates `.env.fetched` if `.env` already exists

### Multi-Environment Support

Each environment is stored as a separate KeePass entry:
- Development: `{project}/development`
- Staging: `{project}/staging`
- Production: `{project}/production`

Default environment is "development" (configurable via `default_env`).

## File Patterns

**Shell completions:** `completions/kpenv.bash` (Bash), `completions/_kpenv` (Zsh)
**Tests:** `tests/Unit/*Test.php` (Pest framework)
**Documentation:** `docs/` directory
**Example files:** Tool searches for `.env.example`, `env.example`, `.env.dist`, `example.env` (in order)

## Distribution Strategy

The project uses a phased distribution approach:
- **v1.1 (current):** Installation scripts, configuration system, `init` command
- **v1.2 (planned):** Composer package on Packagist, list/diff commands
- **v2.0 (future):** APT/Homebrew packages, PSR-4 refactor, plugin system

## Testing Philosophy

Tests use Pest framework. The main executable (`kpenv`) is loaded in `tests/Pest.php` to access internal functions for unit testing. When adding new functions to `kpenv`, ensure they can be tested by not wrapping all code in the main execution guard.

## Common Gotchas

- PHP version MUST be 8.2+ (uses strict types, `str_starts_with`, etc.)
- The script uses `declare(strict_types=1)` - be careful with type coercion
- KeePassXC CLI tool must be installed separately (not bundled)
- Windows support requires Unix-like shell (Git Bash, WSL, MSYS2, or Cmder)
- Project detection relies on `base_dev_folder` config setting or git remote URL

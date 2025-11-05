# Product Requirements Document: kpenv (KeePass Environment Manager)

**Version:** 1.0
**Date:** 2025-11-05
**Status:** Implemented
**Author:** Human + Claude collaboration

---

## Executive Summary

### Vision

Create a simple, secure command-line tool for managing `.env` files across development teams and machines using KeePassXC as a backend. Eliminate the need to commit secrets to git while enabling easy environment setup on new machines.

### Key Objectives

- Provide secure storage of environment configurations in KeePass password manager
- Enable quick project setup on new machines (one command to restore `.env`)
- Support multiple environments per project (development, staging, production)
- Interactive sync from `.env.example` for new projects
- Zero configuration for simple use cases

### Success Metrics

- ✅ Working sync/backup/restore functionality (COMPLETE)
- ✅ Multi-environment support (COMPLETE)
- ✅ Secure password handling (COMPLETE)
- ✅ Auto project detection (COMPLETE)
- ✅ Safe restore mode (COMPLETE)

---

## Background & Context

### Current State

**Problem:** Developers face the challenge of managing environment files (`.env`) across multiple machines and team members. Current approaches have issues:

- ❌ Committing `.env` to git → Security risk (secrets exposed)
- ❌ Manual copy/paste → Error-prone, slow
- ❌ Shared drives/Dropbox → Not always secure, sync conflicts
- ❌ Documentation (README with instructions) → Tedious, outdated quickly

### Problem Statement

Development teams need a secure, repeatable way to:
1. Share environment configurations without committing secrets to git
2. Set up `.env` files on new machines quickly
3. Manage multiple environments (dev/staging/prod) per project
4. Keep `.env.example` in sync with actual `.env` files

### Why This Solution?

**Advantages of KeePass as Backend:**
- ✅ Already used by many developers for password management
- ✅ Strong encryption (AES-256, Argon2)
- ✅ Cross-platform (Windows, macOS, Linux)
- ✅ Supports team sharing (shared database files)
- ✅ CLI available (`keepassxc-cli`) for automation
- ✅ Entry notes can store arbitrary text (perfect for `.env` files)

**Why PHP:**
- ✅ Ubiquitous in web development
- ✅ Simple scripting without compilation
- ✅ Good string handling and file operations
- ✅ Easy to read and modify

---

## Core Requirements

### Functional Requirements

#### FR-1: Sync from Example

**Description:** Create or update `.env` from `.env.example` with interactive prompts for new keys.

**User Story:**
- As a developer, I want to sync `.env.example` to `.env` and be prompted for missing values, so I don't have to manually copy the file and fill in values.

**Acceptance Criteria:**
- [x] Reads `.env.example` file
- [x] Compares with existing `.env` (if present)
- [x] Prompts for values of new keys not in `.env`
- [x] Appends new keys to `.env`
- [x] Reports number of keys added
- [x] Works with different environment names (`--env=staging`)

**Priority:** Must Have ✅

---

#### FR-2: Backup to KeePass

**Description:** Backup `.env` file content to KeePass entry notes for secure storage.

**User Story:**
- As a developer, I want to backup my `.env` file to KeePass, so I can restore it on other machines or share with team members securely.

**Acceptance Criteria:**
- [x] Reads `.env` file content
- [x] Auto-detects project name from directory path
- [x] Creates KeePass entry at `{project-name}/{environment}` path
- [x] Stores `.env` content in entry notes
- [x] Creates groups if they don't exist
- [x] Confirms successful backup
- [x] Handles password input securely (stdin/env var)

**Priority:** Must Have ✅

---

#### FR-3: Restore from KeePass

**Description:** Restore `.env` file from KeePass entry notes.

**User Story:**
- As a developer setting up a project on a new machine, I want to restore my `.env` file from KeePass with one command, so I can start working immediately.

**Acceptance Criteria:**
- [x] Retrieves content from KeePass entry `{project-name}/{environment}`
- [x] Creates `.env` file with retrieved content
- [x] Safe mode: If `.env` exists, creates `.env.fetched` instead
- [x] Confirms successful restore
- [x] Clear error message if entry not found

**Priority:** Must Have ✅

---

#### FR-4: Multi-Environment Support

**Description:** Support multiple environments per project (development, staging, production).

**User Story:**
- As a developer, I want to manage separate `.env` files for development, staging, and production, so I can easily switch contexts.

**Acceptance Criteria:**
- [x] `--env` flag to specify environment name
- [x] Default to "development" if not specified
- [x] Maps to `.env` (development) or `.env.{name}` (others)
- [x] KeePass path: `{project}/{environment}`

**Priority:** Must Have ✅

---

#### FR-5: Auto Project Detection

**Description:** Automatically detect project name from current directory path.

**User Story:**
- As a developer, I don't want to manually specify the project name every time, the tool should infer it from my directory structure.

**Acceptance Criteria:**
- [x] Detects project name from path: `/base/dev/folder/{project-name}/`
- [x] Configurable base folder path
- [x] Clear error if not under configured base folder

**Priority:** Must Have ✅

---

### Non-Functional Requirements

#### NFR-1: Security

- Password never stored in code or config
- Password input hidden (stdin with `stty -echo`)
- Support for `KEEPASS_PASSWORD` environment variable
- Password passed to `keepassxc-cli` via stdin (not command line)
- Safe restore mode (won't overwrite without confirmation)

#### NFR-2: Usability

- Simple command structure: `kpenv {command} [--options]`
- Clear help text (`--help`)
- Interactive prompts for missing information
- Informative error messages
- Zero configuration for simple use cases

#### NFR-3: Reliability

- Validates KeePass database exists
- Validates `keepassxc-cli` is installed
- Creates KeePass groups if needed
- Graceful error handling

#### NFR-4: Performance

- Near-instant for sync operation (< 1s)
- Backup/restore dependent on KeePass database size (typically < 2s)

---

## Technical Architecture

### Components

```
kpenv (Single PHP File)
├── Configuration (top of file)
├── KeePassXCService class
│   ├── getEntryNotes()
│   ├── setEntryNotes()
│   ├── ensureGroupExists()
│   └── execute() [private]
├── main() function
│   └── Command routing
├── Helper functions
│   ├── parse_env_file()
│   ├── sync_example_locally()
│   ├── backup_env_to_keepass()
│   ├── restore_env_from_keepass()
│   ├── get_project_name()
│   └── show_help()
```

### Data Flow

**Backup Flow:**
```
.env file → read content → KeePassXCService
→ keepassxc-cli edit --notes
→ KeePass database (entry notes updated)
```

**Restore Flow:**
```
KeePass database → keepassxc-cli show --attributes Notes
→ KeePassXCService → write to .env file
```

**Sync Flow:**
```
.env.example (parse keys)
→ compare with .env
→ prompt for missing keys
→ append to .env
```

### KeePass Structure

```
KeePass Database
└── {project-name}/
    ├── development
    │   └── Notes: [full .env content]
    ├── staging
    │   └── Notes: [full .env.staging content]
    └── production
        └── Notes: [full .env.production content]
```

---

## Implementation Status

### Version 1.0 (Current) - ✅ COMPLETE

- [x] Core sync/backup/restore functionality
- [x] KeePassXCService wrapper class
- [x] Multi-environment support (`--env` flag)
- [x] Interactive prompts for sync
- [x] Secure password handling
- [x] Safe restore mode
- [x] Auto project detection
- [x] Help text
- [x] Error handling

**Total Implementation:** ~300 lines of PHP

**Completed:** Pre-2025-11-05 (exact date unknown)

### Version 1.1 (Planned)

- [ ] List command: Show all backed-up projects/environments
- [ ] Diff command: Compare local vs KeePass version
- [ ] Config file support (`kpenv.json` in project root)
- [ ] PHPUnit test suite
- [ ] CI/CD integration (GitHub Actions)

### Version 2.0 (Future)

- [ ] Refactor to PSR-4 class structure
- [ ] Composer package (`composer global require local/kpenv`)
- [ ] Plugin system for other backends (1Password, Bitwarden, Vault)
- [ ] GUI wrapper (Electron or Tauri)
- [ ] Template system for common stacks (Laravel, Symfony, etc.)

---

## Success Criteria

### MVP Checklist (v1.0)

- [x] `sync-example` command works
- [x] `backup-env` command works
- [x] `restore-env` command works
- [x] Multi-environment support
- [x] Secure password handling
- [x] Project name auto-detection
- [x] Safe restore (`.env.fetched` mode)
- [x] Help text
- [x] Executable (`chmod +x kpenv`)
- [x] Shebang (`#!/usr/bin/env php`)

### Documentation Checklist

- [x] README with usage examples
- [x] LICENSE (MIT)
- [x] composer.json
- [x] Example `.env.example` file
- [x] PRD (this document)
- [ ] Implementation plan
- [ ] Session log
- [ ] Decisions log

---

## Open Questions

### Resolved

1. ✅ **Storage format:** Use KeePass entry notes (simple, works well)
2. ✅ **Password security:** stdin with hidden input + env var support
3. ✅ **Project detection:** Parse from directory path
4. ✅ **Safe restore:** Create `.env.fetched` if `.env` exists

### To Be Decided (v1.1+)

1. **Config file location:** Project root vs `~/.config/kpenv/`?
2. **List command format:** Table or JSON output?
3. **Diff format:** Unified diff or side-by-side?
4. **Testing strategy:** Unit tests vs integration tests vs both?

---

## Appendix

### Glossary

- **.env:** Environment file containing configuration key-value pairs
- **KeePassXC:** Cross-platform password manager with strong encryption
- **keepassxc-cli:** Command-line interface for KeePassXC
- **.kdbx:** KeePass database file format

### References

- KeePassXC: https://keepassxc.org/
- KeePassXC CLI Docs: https://keepassxc.org/docs/KeePassXC_UserGuide.html#_command_line_interface
- Planning Framework: `docs/planning/FRAMEWORK.md`

---

**Document History:**
- v1.0 (2025-11-05) - Initial PRD created during extraction from lora-vat project

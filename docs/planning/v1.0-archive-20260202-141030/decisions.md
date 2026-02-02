# Architecture Decision Log - kpenv

**Project:** kpenv (KeePass Environment Manager)
**Started:** 2025-11-05 (retroactive documentation)
**Last Updated:** 2025-11-05

---

## Decision Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](#adr-001-use-keepass-entry-notes-for-storage) | Use KeePass Entry Notes for Storage | Accepted | 2025-11-05* |
| [ADR-002](#adr-002-single-file-architecture) | Single File Architecture | Accepted | 2025-11-05* |
| [ADR-003](#adr-003-php-as-implementation-language) | PHP as Implementation Language | Accepted | 2025-11-05* |
| [ADR-004](#adr-004-project-name-auto-detection) | Project Name Auto-Detection | Accepted | 2025-11-05* |
| [ADR-005](#adr-005-safe-restore-mode) | Safe Restore Mode | Accepted | 2025-11-05* |

*Retroactive documentation of decisions made during original development

---

## Decisions

### ADR-001: Use KeePass Entry Notes for Storage

**Date:** 2025-11-05 (retroactive)
**Status:** Accepted

#### Context

Need to store `.env` file content in KeePass database. Several options for storage:

1. Entry password field (limited length, not ideal for multi-line content)
2. Entry notes field (unlimited length, supports multi-line)
3. Attachments (requires file handling, more complex)
4. Custom attributes (not widely supported)

#### Options Considered

**Option 1: Entry Password Field**
- Pros: Easy to access
- Cons: Limited length, not designed for multi-line content, visible in password history

**Option 2: Entry Notes Field**
- Pros: Unlimited length, supports multi-line, designed for arbitrary text
- Cons: None significant

**Option 3: Attachments**
- Pros: Proper file storage
- Cons: More complex API, requires temp file creation, harder to edit manually

#### Decision

**Use KeePass entry notes field for storing `.env` content**

#### Rationale

- Notes field is designed for arbitrary text content
- Unlimited length (can store large `.env` files)
- Native multi-line support
- Easy to edit manually in KeePassXC GUI if needed
- Simple API: `keepassxc-cli show --attributes Notes`
- No temp file handling required

#### Consequences

**Positive:**
- Simple implementation (read/write notes)
- Manual editing possible (via KeePassXC GUI)
- No size limits
- Clean separation (one entry per environment)

**Negative:**
- Notes field could be used for other purposes (convention: use dedicated entries)
- No syntax highlighting in KeePass GUI (minor inconvenience)

---

### ADR-002: Single File Architecture

**Date:** 2025-11-05 (retroactive)
**Status:** Accepted

#### Context

Need to decide project structure for a CLI tool. Options:

1. Single PHP file with all code
2. Multi-file with PSR-4 autoloading
3. Compiled PHAR archive

#### Options Considered

**Option 1: Single PHP File**
- Pros: Easy to distribute, no autoloading needed, simple to understand
- Cons: Less modular, harder to test individual components

**Option 2: PSR-4 Multi-File**
- Pros: Modular, testable, follows best practices
- Cons: Requires autoloading, more complex distribution

**Option 3: PHAR Archive**
- Pros: Single distributable file, can include dependencies
- Cons: Complex build process, may be blocked by php.ini settings

#### Decision

**Use single PHP file architecture for v1.0, plan PSR-4 refactor for v2.0**

#### Rationale

For v1.0:
- Simple tool (~300 lines total)
- Easy to distribute (just copy one file)
- No external dependencies (just PHP and keepassxc-cli)
- Easy to read and understand
- Quick to modify

For v2.0:
- Refactor when tool grows larger
- Better testability will be needed
- Plugin system will require modular design

#### Consequences

**Positive:**
- Extremely easy distribution
- No dependency management needed
- Low barrier to contribution
- Fast startup time

**Negative:**
- Harder to unit test (can be worked around)
- Less modular (acceptable for 300 lines)
- Will need refactoring if tool grows

---

### ADR-003: PHP as Implementation Language

**Date:** 2025-11-05 (retroactive)
**Status:** Accepted

#### Context

Need to choose implementation language for CLI tool. Target audience: web developers using `.env` files.

#### Options Considered

**Option 1: Bash Script**
- Pros: Ubiquitous, no runtime needed
- Cons: Complex string handling, hard to maintain, poor error handling

**Option 2: Python**
- Pros: Excellent for CLI tools, good libraries
- Cons: May not be installed on all systems, version conflicts (2 vs 3)

**Option 3: Go**
- Pros: Single binary, fast, cross-platform
- Cons: Compilation needed, larger distribution size

**Option 4: PHP**
- Pros: Ubiquitous in web dev, good string/file handling, simple scripting
- Cons: Requires PHP installation (usually present)

**Option 5: Node.js**
- Pros: Popular, good CLI libraries (commander, inquirer)
- Cons: Requires npm, node_modules bloat

#### Decision

**Use PHP as implementation language**

#### Rationale

- Target audience (web developers) almost always has PHP installed
- Excellent string and file manipulation
- Simple scripting without compilation
- Good process execution (`proc_open` for `keepassxc-cli`)
- Familiar syntax for web developers
- Single file distribution (no npm install)

#### Consequences

**Positive:**
- Easy to read for web developers
- No build step required
- Good file and string handling
- Process execution well-supported

**Negative:**
- Requires PHP 8.2+ (modern requirement)
- Not as "modern" as Go/Rust
- Slower than compiled languages (not an issue for this use case)

---

### ADR-004: Project Name Auto-Detection

**Date:** 2025-11-05 (retroactive)
**Status:** Accepted

#### Context

Need to determine KeePass entry path for storing `.env` files. User must specify project name somehow.

#### Options Considered

**Option 1: Require --project flag**
- Pros: Explicit, no magic
- Cons: Tedious, repetitive

**Option 2: Auto-detect from git remote**
- Pros: Accurate project name
- Cons: Requires git, may have no remote, slow

**Option 3: Auto-detect from directory path**
- Pros: Fast, always available, predictable
- Cons: Requires conventional directory structure

**Option 4: Config file (kpenv.json)**
- Pros: Flexible, explicit
- Cons: Additional file to maintain

#### Decision

**Auto-detect project name from directory path, with configurable base folder**

Path structure: `/path/to/base/dev/folder/{project-name}/...`
KeePass entry: `{project-name}/{environment}`

#### Rationale

- Most developers organize projects in a consistent way
- Fast (no external commands)
- Predictable (same directory = same project name)
- Zero configuration for 90% of use cases
- Can be configured if needed (change `$baseDevFolder`)

#### Consequences

**Positive:**
- Zero configuration for typical usage
- Fast and reliable
- Predictable behavior
- Works without git

**Negative:**
- Requires conventional directory structure
- Base folder must be configured correctly
- Doesn't work if project is outside base folder (shows error)

---

### ADR-005: Safe Restore Mode

**Date:** 2025-11-05 (retroactive)
**Status:** Accepted

#### Context

When restoring `.env` from KeePass, local `.env` file might already exist. Behavior options:

1. Overwrite existing `.env`
2. Prompt for confirmation before overwriting
3. Create `.env.fetched` instead and show warning
4. Error and abort

#### Options Considered

**Option 1: Overwrite**
- Pros: Simple, matches command intent
- Cons: Could lose local changes, dangerous

**Option 2: Prompt for Confirmation**
- Pros: Safe, gives user control
- Cons: Blocks automation, requires interaction

**Option 3: Create .env.fetched**
- Pros: Safe, non-destructive, allows comparison
- Cons: Extra step for user

**Option 4: Error and Abort**
- Pros: Safest
- Cons: Forces manual deletion, annoying

#### Decision

**Create `.env.fetched` if `.env` exists, show warning message**

```
Warning: Local file '.env' already exists.
Saving content from KeePass to '.env.fetched' instead.
```

User can then:
- Compare files: `diff .env .env.fetched`
- Replace: `mv .env.fetched .env`
- Merge manually

#### Rationale

- Non-destructive (never loses data)
- Allows manual comparison before replacing
- Works in automated scripts (no prompt)
- Clear user communication (shows warning)
- Common pattern (`.bak`, `.fetched`, `.new` suffixes)

#### Consequences

**Positive:**
- No accidental data loss
- User can review before replacing
- Works in scripts (no interaction)
- Clear what happened

**Negative:**
- Extra manual step (mv .env.fetched .env)
- Could accumulate .fetched files (minor)
- Not fully automatic (trade-off for safety)

---

## Future Decisions (To Be Made)

### For v1.1

1. **List Command Output Format:** Table vs JSON vs YAML?
2. **Diff Command Format:** Unified diff vs side-by-side vs custom?
3. **Config File Location:** Project root vs `~/.config/kpenv/` vs both?
4. **Config File Format:** JSON vs YAML vs TOML?

### For v2.0

1. **Plugin Architecture:** Interface design for multiple backends?
2. **GUI Framework:** Electron vs Tauri vs native?
3. **Distribution:** Packagist only vs multiple package managers?

---

**Log Started:** 2025-11-05
**Last Updated:** 2025-11-05

**Note:** ADRs 001-005 are retroactive documentation of decisions made during original development. Future ADRs will be written at decision time.

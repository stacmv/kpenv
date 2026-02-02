# Issue Prompt

**Date:** 2026-02-02
**Type:** improve
**Issue ID:** 20260202-improve-sync-example-hints

---

## Original Request

Проверь, команда sync-example показывает подсказки из example файла и спрашивает нужно ли вызвать backup-env, если были внесены изменения.

По подсказкам: нужно отображать не только строки комментариями, но и строки с комментариями после значений, например:
```bash
DATABASE_HOST=localhost # Host Name.
```

---

## Problem Description

The `sync-example` command currently has two issues:

### 1. Missing Hints from Example File

When prompting users for new environment variable values, the command does not show helpful comments/hints from the `.env.example` file.

**Example `.env.example` file:**
```bash
# Database host (use localhost for development)
DATABASE_HOST=localhost

DATABASE_PORT=5432 # PostgreSQL default port
```

**Current behavior:**
```
New key 'DATABASE_HOST' found. Enter value (default: localhost):
New key 'DATABASE_PORT' found. Enter value (default: 5432):
```

**Expected behavior:**
```
# Database host (use localhost for development)
New key 'DATABASE_HOST' found. Enter value (default: localhost):

# PostgreSQL default port
New key 'DATABASE_PORT' found. Enter value (default: 5432):
```

The command should display:
- Comment lines that appear **before** the variable (standalone comment lines starting with #)
- Inline comments that appear **after** the variable value (e.g., `KEY=value # comment`)

### 2. No Backup Prompt After Changes

After successfully adding new keys to `.env`, the command should ask the user if they want to backup the updated file to KeePass.

**Current behavior:**
```
Sync completed. 2 keys added to .env.
```
(Command ends)

**Expected behavior:**
```
Sync completed. 2 keys added to .env.

Would you like to backup .env to KeePass now? [Y/n]:
```

If user confirms (Y or Enter), automatically call the backup-env command.

---

## Requirements

1. **Show comment hints when prompting for values:**
   - Display standalone comment lines (lines starting with `#`) that appear immediately before the variable
   - Display inline comments (text after `#` on the same line as `KEY=value`)
   - Preserve the original formatting and spacing

2. **Interactive backup prompt after sync:**
   - Only prompt if changes were made (`$addedCount > 0`)
   - Default to "Yes" (press Enter to backup)
   - Accept Y/y/yes/Enter as confirmation
   - Accept N/n/no to skip
   - Call the existing `backup_env_to_keepass()` function if confirmed

3. **Maintain backward compatibility:**
   - Don't break existing .env file parsing
   - Don't change the output format of the .env file
   - Keep the same command-line arguments

---

## Files Involved

- `kpenv` - Main executable
  - Function: `sync_example_locally()` (lines ~568-675)
  - Function: `parse_env_line()` (lines ~493+)
  - May need to track comment context while parsing

---

## Acceptance Criteria

- [ ] When sync-example prompts for a new variable, it displays any comment that appears before the variable in .env.example
- [ ] When sync-example prompts for a new variable, it displays any inline comment (after #) from .env.example
- [ ] After adding keys, if any changes were made, prompt user to backup to KeePass
- [ ] Backup prompt accepts Y/n with Y as default
- [ ] If user confirms backup, automatically execute backup-env command
- [ ] All existing sync-example functionality continues to work
- [ ] Manual testing confirms hints display correctly for various comment formats

---

## Test Cases

**Test 1: Standalone comment before variable**
```bash
# .env.example
# This is the database host
DATABASE_HOST=localhost
```
Should show: "# This is the database host" before prompting

**Test 2: Inline comment after variable**
```bash
# .env.example
DATABASE_PORT=5432 # PostgreSQL default port
```
Should show: "# PostgreSQL default port" when prompting

**Test 3: Multiple comment lines**
```bash
# .env.example
# Database configuration
# Use localhost for development
DATABASE_HOST=localhost
```
Should show both comment lines before prompting

**Test 4: Backup prompt when changes made**
```bash
$ kpenv sync-example
New key 'DATABASE_HOST' found. Enter value (default: localhost): localhost
Sync completed. 1 keys added to .env.

Would you like to backup .env to KeePass now? [Y/n]:
```

**Test 5: No backup prompt when no changes**
```bash
$ kpenv sync-example
Sync completed. 0 keys added to .env.
```
(No backup prompt since nothing changed)

---

## Priority

**Medium** - Improves user experience and encourages best practice (backing up after changes), but doesn't block current functionality.

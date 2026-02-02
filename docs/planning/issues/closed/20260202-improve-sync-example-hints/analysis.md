# Issue Analysis

---
**issue_id:** 20260202-improve-sync-example-hints
**type:** improve
**status:** open
**priority:** medium
**created:** 2026-02-02
**assigned_to:**
---

## Problem Understanding

The `sync-example` command currently works but provides a suboptimal user experience:

1. **Missing context**: Users don't see helpful comments from `.env.example` when entering values
2. **Missing workflow step**: No prompt to backup changes to KeePass after modifying `.env`

Both issues reduce usability and could lead to:
- Users entering incorrect values (missing hints)
- Users forgetting to backup changes (manual extra step)

## Current Implementation Analysis

### Comment Parsing (parse_env_line function)

**Location:** `kpenv` lines ~493-565

**Current behavior:**
```php
if (str_starts_with($trimmed, '#')) {
    return ['type' => 'comment', 'line' => $line];
}
```

Comments are detected but their content is not extracted or associated with the following variable. The function returns:
- `type: 'comment'` for standalone comment lines
- `type: 'variable'` for variable lines (but doesn't extract inline comments)

**Issue:** No parsing of inline comments (after the value on same line)

### Sync Logic (sync_example_locally function)

**Location:** `kpenv` lines ~568-675

**Current flow:**
1. Parse existing .env to get current keys
2. Loop through .env.example lines
3. For each variable, check if it exists locally
4. If new variable, prompt user for value
5. Write all new variables to .env
6. Display count of added keys
7. **Exit** (no backup prompt)

**Issues identified:**
- Comments are skipped in the loop (lines 617-622) without being stored
- No context tracking between comment lines and variable lines
- No backup prompt at the end

## Proposed Solution

### Part 1: Display Comment Hints

**Approach:** Track comments as we parse, associate them with the next variable

**Implementation strategy:**
1. Modify parsing loop to accumulate comments
2. When a variable is encountered, display accumulated comments before prompting
3. Parse and display inline comments from the variable line

**Code changes needed:**
```php
// In sync_example_locally function, before the foreach loop:
$pendingComments = []; // Track comments before next variable

foreach ($exampleLines as $line) {
    $parsed = parse_env_line($line);

    if ($parsed['type'] === 'comment') {
        // Store comment for next variable
        $pendingComments[] = $parsed['line'];
        continue;
    }

    if ($parsed['type'] === 'variable') {
        // Display accumulated comments
        if (!empty($pendingComments)) {
            echo "\n" . implode("\n", $pendingComments) . "\n";
            $pendingComments = []; // Clear after displaying
        }

        // Display inline comment if exists
        if (isset($parsed['inline_comment'])) {
            echo "# " . $parsed['inline_comment'] . "\n";
        }

        // ... existing prompt logic ...
    }

    if ($parsed['type'] === 'empty') {
        // Clear pending comments on empty line (comment block ended)
        $pendingComments = [];
    }
}
```

**Also need to enhance parse_env_line:**
- Extract inline comments from variable lines
- Return `inline_comment` in the result array

### Part 2: Backup Prompt

**Approach:** Add interactive prompt after sync completes if changes were made

**Implementation strategy:**
```php
// At the end of sync_example_locally function:
echo "Sync completed. $addedCount keys added to $envFile.\n";

if ($addedCount > 0) {
    echo "\nWould you like to backup $envFile to KeePass now? [Y/n]: ";
    $answer = trim(fgets(STDIN));

    if ($answer === '' || strtolower($answer) === 'y' || strtolower($answer) === 'yes') {
        echo "\n";
        // Get project name
        $project = detect_project_name($config);

        // Get or prompt for KeePass password
        $password = getenv('KEEPASS_PASSWORD');
        if (!$password) {
            echo "KeePass database password: ";
            system('stty -echo');
            $password = trim(fgets(STDIN));
            system('stty echo');
            echo "\n";
        }

        // Create KeePass service and backup
        try {
            $kp = new KeePassXCService($config->get('keepass_db'), $password);
            backup_env_to_keepass($kp, $project, $env, $config);
        } catch (Exception $e) {
            echo "Error: " . $e->getMessage() . "\n";
            exit(1);
        }
    } else {
        echo "Skipped backup. You can backup later with: kpenv backup-env\n";
    }
}
```

## Technical Considerations

### 1. Comment Association Logic

**Challenge:** How to know which comments belong to which variable?

**Solution:**
- Comments immediately before a variable (no empty line between) belong to that variable
- Empty line resets the comment accumulator
- Inline comments always belong to the same line's variable

### 2. Inline Comment Parsing

**Challenge:** Distinguish between `#` in values vs comments

**Example problematic case:**
```bash
PASSWORD="my#password123" # This is a comment
```

**Solution:**
- Parse the value first (respecting quotes)
- After the closing quote (or after unquoted value), look for `#`
- Everything after `#` is a comment

**Code approach:**
```php
// After extracting value in parse_env_line:
$inlineComment = null;
if ($hasQuotes) {
    // After closing quote, check for # comment
    $afterValue = substr($valuePart, $pos + 1);
    if (preg_match('/\s*#\s*(.+)$/', $afterValue, $matches)) {
        $inlineComment = trim($matches[1]);
    }
} else {
    // For unquoted values, # marks comment start
    if (strpos($value, '#') !== false) {
        list($actualValue, $comment) = explode('#', $value, 2);
        $value = trim($actualValue);
        $inlineComment = trim($comment);
    }
}
```

### 3. Password Handling for Backup

**Challenge:** User might not have KEEPASS_PASSWORD set

**Solution:**
- Check for KEEPASS_PASSWORD env var first
- If not set, prompt for password securely (stty -echo)
- Pass to KeePassXCService constructor

### 4. Error Handling

**Scenarios to handle:**
- KeePass database not accessible during backup prompt
- Incorrect password
- Network issues (if KeePass on network drive)

**Approach:**
- Wrap backup call in try-catch
- Show clear error message
- Don't fail the entire sync-example if backup fails
- Suggest running `kpenv backup-env` manually later

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Complex inline comment parsing breaks value extraction | High | Extensive unit tests for parse_env_line with various formats |
| Backup prompt annoys users who don't use KeePass | Medium | Make it optional, easy to skip (just press 'n') |
| Password prompt breaks non-interactive scripts | Medium | Check if STDIN is a TTY before prompting; skip if non-interactive |
| Performance impact from additional parsing | Low | Minimal - only parses example file once |

## Dependencies

- No external dependencies
- Uses existing functions: `backup_env_to_keepass()`, `detect_project_name()`, `KeePassXCService`
- Requires TTY for interactive prompts (already required by existing interactive input)

## Testing Strategy

### Unit Tests (Pest)

Create tests for:
1. `parse_env_line()` with inline comments
2. Comment extraction logic
3. Various .env.example formats

**Test file:** `tests/Unit/SyncExampleHintsTest.php`

### Manual Testing

Test scenarios:
1. Sync with standalone comments
2. Sync with inline comments
3. Sync with mixed comment types
4. Backup prompt - accept
5. Backup prompt - decline
6. Backup prompt - with KEEPASS_PASSWORD env var
7. Backup prompt - without password (should prompt)
8. No changes scenario (no backup prompt)

## Success Criteria

### Functional
- [x] Comments display before variable prompts
- [x] Inline comments display before variable prompts
- [x] Backup prompt appears when changes made
- [x] Backup prompt accepts Y/n input
- [x] Backup executes successfully when confirmed
- [x] Can skip backup and continue
- [x] No backup prompt when no changes

### Non-Functional
- [x] Backward compatible with existing .env files
- [x] Performance remains acceptable (<1s for typical files)
- [x] Clear error messages for any failures
- [x] User experience feels natural and helpful

## Implementation Plan

See `implementation-plan.md` for detailed task breakdown.

## Questions & Assumptions

**Q1:** Should we show ALL comments or just the immediate preceding ones?
**A:** Only immediate preceding (no empty line between comment and variable)

**Q2:** What if there are multiple # symbols in a line?
**A:** First # after the value starts the comment

**Q3:** Should backup prompt timeout?
**A:** No - wait for user input (consistent with other prompts)

**Q4:** What if backup-env requires additional args (--env)?
**A:** Use the same $env that was passed to sync-example

## Related Issues

None currently.

## References

- Current implementation: `kpenv` lines 568-675 (sync_example_locally)
- Parser function: `kpenv` lines 493+ (parse_env_line)
- Backup function: `kpenv` lines 677+ (backup_env_to_keepass)

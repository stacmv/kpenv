# Implementation Plan

**Issue:** 20260202-improve-sync-example-hints
**Type:** improve
**Status:** in_progress
**Started:** 2026-02-02

---

## Tasks

### Phase 1: Enhance Comment Parsing

- [ ] **Task 1.1:** Modify `parse_env_line()` to extract inline comments
  - Parse comments after values (e.g., `KEY=value # comment`)
  - Handle quoted values properly (don't treat # inside quotes as comment)
  - Return `inline_comment` field in result array
  - Location: `kpenv` ~lines 493-565

- [ ] **Task 1.2:** Write unit tests for inline comment parsing
  - Test: Simple inline comment `KEY=value # comment`
  - Test: Quoted value with # inside `KEY="val#ue" # comment`
  - Test: Single quotes `KEY='value' # comment`
  - Test: No inline comment `KEY=value`
  - Location: `tests/Unit/ParseEnvLineTest.php`

### Phase 2: Display Hints in sync-example

- [ ] **Task 2.1:** Track pending comments while parsing .env.example
  - Add `$pendingComments = []` array before loop
  - Accumulate comment lines as they're encountered
  - Clear on empty lines (comment block ended)
  - Location: `kpenv` `sync_example_locally()` function

- [ ] **Task 2.2:** Display comments before prompting for variable
  - Show accumulated standalone comments
  - Show inline comment if present
  - Clear pending comments after displaying
  - Location: `kpenv` `sync_example_locally()` function

- [ ] **Task 2.3:** Manual testing of comment display
  - Test with standalone comments
  - Test with inline comments
  - Test with mixed comment types
  - Test with no comments

### Phase 3: Add Backup Prompt

- [ ] **Task 3.1:** Add interactive backup prompt after sync
  - Check if `$addedCount > 0`
  - Prompt: "Would you like to backup .env to KeePass now? [Y/n]:"
  - Accept Y/y/yes/Enter as confirmation
  - Location: `kpenv` `sync_example_locally()` end of function

- [ ] **Task 3.2:** Implement backup execution on confirmation
  - Get project name using `detect_project_name()`
  - Check for `KEEPASS_PASSWORD` env var
  - If not set, prompt for password securely (stty -echo)
  - Create `KeePassXCService` instance
  - Call `backup_env_to_keepass()`
  - Handle errors gracefully

- [ ] **Task 3.3:** Manual testing of backup prompt
  - Test with KEEPASS_PASSWORD set
  - Test without password (should prompt)
  - Test declining backup (n)
  - Test accepting backup (y)
  - Test with invalid password
  - Test when no changes made (no prompt)

### Phase 4: Testing & QA

- [ ] **Task 4.1:** Run all existing tests
  - `composer test`
  - Ensure no regressions

- [ ] **Task 4.2:** Run linting
  - `php -l kpenv`
  - Fix any syntax errors

- [ ] **Task 4.3:** Manual integration testing
  - Create test .env.example with various comment types
  - Run sync-example and verify hints display
  - Verify backup prompt appears and works
  - Test complete workflow end-to-end

- [ ] **Task 4.4:** Update documentation if needed
  - Check if README.md needs updates
  - Document new behavior if necessary

### Phase 5: Commit & Close

- [ ] **Task 5.1:** Commit changes with clear message
- [ ] **Task 5.2:** Update session-log.md
- [ ] **Task 5.3:** Run QA workflow from .qa-workflow.md
- [ ] **Task 5.4:** Merge to develop
- [ ] **Task 5.5:** Move issue to closed/
- [ ] **Task 5.6:** Update global implementation-plan.md

---

## Progress

**Started:** 2026-02-02
**Status:** Not started

**Completed Tasks:** 0/19

---

## Notes

- Maintain backward compatibility with existing .env files
- Error handling is critical for backup prompt (user might not have KeePass access)
- Comment association logic: only comments immediately before variable (no empty line)

---

## Blockers

None currently.

---
name: md-linter
description: Pre-push quality check for markdown documentation. Fix formatting issues using markdownlint-cli2. Use when asked to "check my documents", "review before I push", "run the linter", "lint my markdown", "fix markdown errors", "fix MD029", "my numbered list is broken", or "resolve ordered list issues" across one or more .md files.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
---

# MD Linter

## Contents

- [Overview](#overview)
- [When to Use This Skill](#when-to-use-this-skill)
- [Execution Model](#execution-model)
- [Workflow Process](#workflow-process)
  - [Phase 1: Environment Setup & Prerequisites](#phase-1-environment-setup--prerequisites)
  - [Phase 2: Diagnostic Assessment](#phase-2-diagnostic-assessment)
  - [Phase 3: Issue Analysis](#phase-3-issue-analysis)
  - [Phase 4: Automatic Fixes](#phase-4-automatic-fixes)
  - [Phase 5: Manual Fixes](#phase-5-manual-fixes)
  - [Phase 6: Verification & Reporting](#phase-6-verification--reporting)
- [Quick Reference Checklist](#quick-reference-checklist)
- [Key Principles](#key-principles)
- [Common Scenarios](#common-scenarios)
- [Resources](#resources)

## The Cardinal Rule: Never Alter Content

A linter fixes **formatting** — whitespace, blank lines, indentation, list markers, heading syntax. It does not touch the words the author wrote. Rephrasing, shortening, rewording, or restructuring text to satisfy a lint rule is not a fix — it's corruption of the author's work.

If a lint rule can only be satisfied by changing what the text *says* (not how it's *formatted*), the correct response is one of:
1. Disable the rule in the config file
2. Report it to the user and let them decide (they may want an inline suppression comment, a config change, or to rewrite the text themselves)

This applies to every rule, but especially to **MD013 (line length)**. Long headings, long sentences, and long URLs cannot be "fixed" by rewriting them. Disable MD013 or suppress it — never shorten prose to fit a character limit.

## Overview

Pre-push quality gate for markdown documentation. Writers run this before pushing to GitHub to catch formatting issues that would affect rendering — broken numbered lists, inconsistent spacing, heading hierarchy problems, malformed tables. The linter ensures documents are well-formed so readers see clean, correctly rendered content.

Systematically diagnoses, auto-fixes where possible, and guides manual fixes when needed, using markdownlint-cli2.

## When to Use This Skill

Use this skill when:

- Checking documents before pushing to GitHub
- Reviewing newly written or edited documents for formatting issues
- Fixing rendering problems — numbered lists restarting, headings out of order, inconsistent spacing
- Addressing ordered list numbering issues (MD029) — especially common in procedures with sub-content between steps
- Standardizing formatting across a documentation repository
- Setting up markdown linting for the first time in a repo

## Execution Model

This skill uses a hybrid execution model to keep diagnostic noise out of the user's conversation while preserving interactive control over decisions that affect their files.

**Subagent (phases 1-3):** Delegate phases 1-3 to a subagent to handle environment setup, diagnostic scanning, and issue analysis. These phases are non-interactive — they only read state and produce a report. The subagent's prompt should include the full text of phases 1-3 below, the path to the project being linted, and the scan scope (specific files named by the user, changed files for a pre-push check, or full repo for setup/cleanup — see Phase 2).

The subagent must return a structured diagnostic report containing:

- Whether markdownlint-cli2 was available (and how it was resolved)
- Whether a config file existed or was created
- The complete list of errors: file path, line number, error code, description
- Error counts grouped by type
- Which errors are auto-fixable vs. require manual attention
- Any MD029 or MD013 errors flagged specifically (these need special handling)

**Main session (phases 4-6):** Once the diagnostic report is returned, present a summary to the user and proceed with auto-fix, manual fixes, and verification interactively. These phases modify files and require user decisions — the user must be able to approve the git safety check, weigh in on unfixable rules like MD013, and confirm any config changes.

**Cross-platform note:** This skill follows the [Agent Skills](https://agentskills.io) open standard. The subagent delegation above works on any platform that supports spawning subagents (e.g., Claude Code's Agent tool, Codex's spawn_agent). On platforms without subagent support, run all 6 phases sequentially in the main session — the workflow is identical, the diagnostic output just appears inline.

## Workflow Process

### Phase 1: Environment Setup & Prerequisites

#### Verify markdownlint-cli2 Availability

Check if markdownlint-cli2 is available locally in the project:

```bash
npx markdownlint-cli2 --version
```

Use `npx markdownlint-cli2` for all commands — this avoids global installs and permission issues. If the project already has it as a dev dependency, npx will use that version. If not, npx will fetch it on demand.

Only if npx is unavailable, fall back to:
- Local installation: `npm install --save-dev markdownlint-cli2`
- Do not install globally with `npm install -g`

#### Configuration File Check

Look for existing markdown configuration files in the project root:

- `.markdownlint-cli2.jsonc`
- `.markdownlint.json`
- `.markdownlint.yaml`
- `.markdownlint.yml`
- `.markdownlintrc`

If none exist, create `.markdownlint-cli2.jsonc` with:

```json
{
  "config": {
    "MD013": false
  },
  "ignores": []
}
```

This disables max line length warnings while keeping other rules active. The `ignores` array can be used to exclude specific files from linting (e.g., example files with intentional errors).

**IMPORTANT - Configuration Policy**:

- **Do not ignore/hide linting errors** by modifying `.markdownlint-cli2.jsonc`
- **Only modify the `ignores` array** based on:
  - Explicit user input or approval
  - Content from `.gitignore` file (files already ignored by git)
- **Always ask the user** before adding files to the ignore list
- **Never suppress errors** without user consent - fix them instead

### Phase 2: Diagnostic Assessment

#### Determine Scan Scope

Before scanning, determine what to lint based on the user's request:

1. **User names specific files** → scan only those files
2. **Pre-push check** ("check before I push", "run the linter", or similar) → identify markdown files with uncommitted changes (modified, added, or untracked) using git status. Scan only those files. If no markdown files have changed, tell the user everything is clean — no scan needed.
3. **Full repo sweep** ("clean up everything", "set up linting", first-time run, or when no git context is available) → scan all markdown files with `"**/*.md"`

Use the determined scope for all subsequent phases — diagnostics, auto-fix, and verification should all target the same set of files.

#### Run Diagnostic Scan

Run the linter against the scoped files:

```bash
# Targeted (specific files or changed files):
npx markdownlint-cli2 "path/to/file1.md" "path/to/file2.md"

# Full repo:
npx markdownlint-cli2 "**/*.md"
```

Document all issues found, including:

- Error codes (e.g., MD029, MD001, MD032)
- File names and line numbers
- Brief description of each issue

### Phase 3: Issue Analysis

#### Categorize Errors by Type

Group all identified linting errors by error code:

- Track frequency of each error type
- Identify which errors are auto-fixable
- Flag special attention areas (especially MD029, which often requires understanding indentation issues)

Common error types:

- **MD001**: Heading levels should increment by one level at a time
- **MD009**: Trailing spaces
- **MD010**: Hard tabs
- **MD012**: Multiple consecutive blank lines
- **MD029**: Ordered list item prefix (requires special attention - often caused by improper indentation)
- **MD032**: Lists should be surrounded by blank lines
- **MD047**: Files should end with a single newline character

Document patterns such as:

- "Found 15 MD029 errors across 5 files"
- "MD032 appears in all documentation files"
- "MD029 errors primarily in files with code blocks within lists"

### --- Subagent returns here. Phases 4-6 run in the main session. ---

Present the diagnostic report to the user before proceeding. Summarize: how many files were scanned, total error count, breakdown by type, and any errors that will need user decisions (MD013, unfixable rules). Then continue with phases 4-6 interactively.

### Phase 4: Automatic Fixes

#### Pre-Fix Safety Check

Before running auto-fix, check if the project is a git repository. If it is, warn the user if there are uncommitted changes to markdown files — auto-fix modifies files in place and having a clean git state gives them an easy undo path via `git checkout`.

#### Execute Auto-Fix

Run the auto-fix command against the same scoped files from Phase 2:

```bash
# Targeted:
npx markdownlint-cli2 "path/to/file1.md" "path/to/file2.md" --fix

# Full repo:
npx markdownlint-cli2 "**/*.md" --fix
```

This command will:

- Automatically fix formatting issues where possible
- Preserve original content intent
- Modify files in place

#### Monitor for Issues

Watch for:

- Errors during the fix process
- Files that couldn't be modified (permissions)
- Any unexpected side effects

Document what was fixed automatically versus what remains.

### Phase 5: Manual Fixes

#### Handle MD029 Issues

For remaining MD029 (ordered list item prefix) issues:

Load and consult `references/MD029-Fix-Guide.md` for detailed guidance on:

- Understanding the root cause: **improper indentation of content between list items**
- Proper 4-space indentation for code blocks within lists
- Indentation requirements for paragraphs, blockquotes, and nested content
- Common mistakes and how to avoid them
- Real-world examples showing before/after fixes
- Alternative solutions and when to use them

**Key insight**: MD029 errors often occur when code blocks, paragraphs, or other content between list items lack proper indentation (typically 4 spaces), causing markdown parsers to break list continuity.

#### Handle MD013 Issues

MD013 (line length) violations cannot be fixed without changing content. When MD013 errors appear after auto-fix:

1. Report them to the user — explain that line length violations require either disabling MD013 in the config or manually rewriting, and ask how they'd like to proceed
2. Never shorten, rewrite, or rephrase lines to reduce their length

#### Apply Manual Corrections

For issues not auto-fixed:

- Open affected files
- Apply fixes according to error type (formatting changes only — indentation, blank lines, list markers, heading syntax)
- Never rewrite, rephrase, shorten, or restructure the author's text
- If a rule cannot be satisfied with a pure formatting change, report it to the user and let them decide how to handle it

#### Documentation-Specific Checks

For documentation-heavy repositories (policies, procedures, guides), check for patterns the linter doesn't fully cover during manual review:

**Mermaid diagrams:** Verify Mermaid blocks use correct fencing — the opening fence must be ` ```mermaid `, not ` ```Mermaid ` or a bare ` ``` ` with no language tag. A malformed fence renders as raw text on GitHub instead of a diagram. The linter sees these as ordinary code blocks and won't flag rendering issues.

**Tables:** The linter catches malformed table structure (inconsistent column counts, missing pipes), but can't verify visual rendering. Complex tables — especially those with long cell content — should be previewed on GitHub, as they may overflow or wrap unexpectedly. Standard Markdown tables do not support block-level content (bullet lists, multi-paragraph text) inside cells. If a document requires this, suggest restructuring as a heading + list pattern or using HTML tables, and let the user decide.

**GitHub callouts:** GitHub supports admonition syntax that renders as styled callout boxes — useful for policy exceptions, warnings, or effective dates:

- `> [!NOTE]` — supplementary information
- `> [!TIP]` — optional advice
- `> [!IMPORTANT]` — critical context
- `> [!WARNING]` — potential issues
- `> [!CAUTION]` — serious risks

The linter treats these as standard blockquotes and won't flag typos in the callout keyword (e.g., `> [!WARINING]` renders as plain text instead of a styled box). Flag any callout-style blockquotes for visual verification.

### Phase 6: Verification & Reporting

#### Re-run Linter

Re-run the linter against the same scoped files to confirm all issues are resolved:

```bash
# Targeted:
npx markdownlint-cli2 "path/to/file1.md" "path/to/file2.md"

# Full repo:
npx markdownlint-cli2 "**/*.md"
```

If no errors appear, linting is complete. If errors remain, document them for additional manual fixes.

#### Generate Summary Report

Provide a comprehensive summary including:

1. **Files Processed**
   - Total count
   - List of files modified
   - Any files skipped or with errors

2. **Issues Fixed by Type**
   - Count of each error type fixed
   - Auto-fixed vs. manually fixed
   - Special notes on MD029 fixes

3. **Remaining Issues** (if any)
   - Error codes still present
   - Files requiring manual attention
   - Recommended next steps

4. **Completion Status**
   - Confirmation of successful completion, or
   - Clear explanation of remaining work needed
   - Any error details with suggested solutions

For routine pre-push checks where everything is clean (or only auto-fixable issues were found), keep the report brief — confirm it's clean and safe to push. Save the detailed breakdown for runs where manual intervention was needed.

## Quick Reference Checklist

- [ ] Verify markdownlint availability: `npx markdownlint-cli2 --version`
- [ ] Create or validate markdownlint config (`.markdownlint-cli2.jsonc` preferred)
- [ ] Determine scan scope: specific files, changed files (pre-push), or full repo
- [ ] Run diagnostics: `npx markdownlint-cli2 <scoped files>`
- [ ] Apply auto-fixes: `npx markdownlint-cli2 <scoped files> --fix`
- [ ] Resolve remaining issues manually using `references/MD029-Fix-Guide.md` and `references/MD036-Guide.md` as needed
- [ ] For documentation repos: verify Mermaid blocks, complex tables, and GitHub callouts render correctly
- [ ] Re-run verification: `npx markdownlint-cli2 <scoped files>`
- [ ] Summarize files changed, issue types fixed, and any remaining blockers

## Key Principles

- **Never alter semantic content.** Do not rewrite, rephrase, shorten, or restructure any text to satisfy a lint rule. If the only way to pass a rule is to change what the text says, report it to the user and let them decide.
- Respect project configuration: do not override existing lint rules unless explicitly requested.
- Do not suppress or hide errors without user consent. When a rule can only be satisfied by changing content, always ask the user rather than silently disabling or rewriting.
- Apply progressive fixing: auto-fix first, then manual fixes for remaining issues.
- Report clearly: what was found, what was fixed, and what still needs action.

## Common Scenarios

| User Request Pattern | Workflow Emphasis | References |
| --- | --- | --- |
| "Check my documents before I push" / "run the linter" | Phase 2 -> Phase 3 -> Phase 4 -> Phase 5 -> Phase 6 | Standard pre-push workflow. Most common invocation. Brief report if clean. |
| "I just wrote a new policy, check it" | Phase 2 (scope to named files) -> Phase 4 -> Phase 5 -> Phase 6 | If user names specific files, scan only those — don't run the full repo sweep. |
| "Fix all markdown errors" / "clean up the whole repo" | Phase 2 -> Phase 3 -> Phase 4 -> Phase 5 -> Phase 6 | Load MD029/MD036 guides only if related errors remain |
| "Fix MD029" / "my numbered list is rendering wrong" | Phase 2 (target MD029) -> Phase 4 -> Phase 5 -> Phase 6 | `references/MD029-Fix-Guide.md` |
| "Set up markdown linting for my repo" | Phase 1 -> Phase 2 -> Phase 4 -> Phase 6 | First-time setup. Create config, run initial scan, fix what's found. |

## Resources

### references/

#### MD029-Fix-Guide.md

Comprehensive guide for handling MD029 (ordered list item prefix) errors, focusing on the root cause: improper indentation. This reference provides:

- Explanation of why MD029 errors occur (content breaking list continuity)
- Proper indentation rules: 4 spaces for code blocks, paragraphs, and other content
- Indentation table showing requirements for different content types
- Common mistakes with clear ❌ wrong vs ✅ correct examples
- Real-world before/after examples
- Alternative solutions and when to use markdownlint-disable comments
- Best practices for maintaining list continuity
- Verification steps

Load this file when MD029 errors persist after auto-fix, or when user needs guidance on fixing ordered list issues. The guide is particularly valuable when lists contain code blocks or mixed content.

#### MD036-Guide.md

Comprehensive style guide for avoiding MD036 (no emphasis as heading) errors. This reference provides:

- Clear explanation of the MD036 rule and why it matters
- Wrong vs. correct examples showing bold text vs. proper heading syntax
- Heading level hierarchy guidelines (h1 through h6)
- Common violations to avoid when creating markdown files
- Best practices for using headings vs. bold text
- Quick checklist for markdown file creation and modification

Load this file when creating new markdown documentation or when encountering MD036 errors. Use as a reference to maintain consistent heading structure and avoid using bold text as heading substitutes.

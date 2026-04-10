---
name: markdown-linter-fixer
description: Fix markdownlint errors in markdown files using markdownlint-cli2. Use when asked to "markdown linter fixer", "run markdownlint", "fix markdown lint errors", "fix MD029", or "resolve ordered list issues" across one or more .md files.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
---

# Markdown Linter Fixer

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

Systematically fix linting issues in `*.md` files using markdownlint-cli2 through a structured workflow that diagnoses, fixes automatically where possible, and guides manual fixes when needed.

## When to Use This Skill

Use this skill when:

- Fixing markdown linting errors in projects
- Standardizing markdown formatting across multiple files
- Addressing ordered list numbering issues (MD029)
- Preparing markdown documentation for quality standards
- Setting up markdown linting for the first time in a project

## Execution Model

This skill uses a hybrid execution model to keep diagnostic noise out of the user's conversation while preserving interactive control over decisions that affect their files.

**Subagent (phases 1-3):** Spawn a subagent using the Agent tool to handle environment setup, diagnostic scanning, and issue analysis. These phases are non-interactive — they only read state and produce a report. The subagent's prompt should include the full text of phases 1-3 below, plus the path to the project being linted.

The subagent must return a structured diagnostic report containing:

- Whether markdownlint-cli2 was available (and how it was resolved)
- Whether a config file existed or was created
- The complete list of errors: file path, line number, error code, description
- Error counts grouped by type
- Which errors are auto-fixable vs. require manual attention
- Any MD029 or MD013 errors flagged specifically (these need special handling)

**Main session (phases 4-6):** Once the diagnostic report is returned, present a summary to the user and proceed with auto-fix, manual fixes, and verification interactively. These phases modify files and require user decisions — the user must be able to approve the git safety check, weigh in on unfixable rules like MD013, and confirm any config changes.

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

#### Initial Root-Level Scan

Run linter on root-level markdown files:

```bash
npx markdownlint-cli2 "*.md"
```

Document all issues found, including:

- Error codes (e.g., MD029, MD001, MD032)
- File names and line numbers
- Brief description of each issue

#### Comprehensive Recursive Scan

Scan all markdown files including subdirectories:

```bash
npx markdownlint-cli2 "**/*.md"
```

This includes files in directories like:

- `docs/`
- `guides/`
- Any other subdirectories containing markdown

Create a complete inventory of all issues across the project.

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

Run the auto-fix command to correct all auto-fixable issues:

```bash
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

### Phase 6: Verification & Reporting

#### Re-run Linter

Confirm all issues are resolved:

```bash
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

## Quick Reference Checklist

- [ ] Verify markdownlint availability: `npx markdownlint-cli2 --version`
- [ ] Create or validate markdownlint config (`.markdownlint-cli2.jsonc` preferred)
- [ ] Run diagnostics: `npx markdownlint-cli2 "**/*.md"`
- [ ] Apply auto-fixes: `npx markdownlint-cli2 "**/*.md" --fix`
- [ ] Resolve remaining issues manually using `references/MD029-Fix-Guide.md` and `references/MD036-Guide.md` as needed
- [ ] Re-run verification: `npx markdownlint-cli2 "**/*.md"`
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
| "Set up markdown linting for my documentation" | Phase 1 -> Phase 2 -> Phase 4 -> Phase 6 | N/A |
| "Fix all markdown linting errors in my project" | Phase 2 -> Phase 3 -> Phase 4 -> Phase 5 -> Phase 6 | Load MD029/MD036 guides only if related errors remain |
| "Fix MD029" / "ordered list issues" | Phase 2 (target MD029) -> Phase 4 -> Phase 5 -> Phase 6 | `references/MD029-Fix-Guide.md` |

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

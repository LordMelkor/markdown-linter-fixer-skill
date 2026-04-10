---
description: Check or fix markdown formatting issues before pushing
---

# MD Linter - {{ARGUMENTS}}

Use the `md-linter` skill to check or fix markdown formatting issues.

**Command format:** `/md-linter:mdlinter [mode] [scope]`

**Arguments:**

- Mode (optional): `{{ARGUMENTS}}`
  - `check` - scan and report issues WITHOUT making changes (DEFAULT)
  - `fix` - scan and automatically fix all issues
  - **Safety default**: If no mode is provided, defaults to `check` mode

- Scope (optional):
  - A specific file, multiple files (space-separated), a folder, or a glob pattern
  - If not provided, scans markdown files with uncommitted changes (pre-push mode)

**Examples:**

- `/md-linter:mdlinter` - check changed files before pushing
- `/md-linter:mdlinter fix` - fix changed files
- `/md-linter:mdlinter README.md` - check only README.md
- `/md-linter:mdlinter fix docs/` - fix all files in docs folder
- `/md-linter:mdlinter check policies/access-control.md` - check a specific policy

**Workflow based on mode:**

**For CHECK mode:**

1. Determine scan scope (changed files, named files, or full repo)
2. Run diagnostic scans
3. Categorize and analyze all errors by type
4. Generate report — brief if clean, detailed if issues found
5. Do NOT make any changes to files

**For FIX mode:**

1. Determine scan scope
2. Run diagnostic scans
3. Apply automatic fixes using --fix flag
4. Handle remaining manual fixes (especially MD029 ordered list issues)
5. Verify all issues are resolved
6. Provide summary report

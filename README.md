# md-linter

Pre-push quality check for markdown documentation. Catches formatting issues that would render incorrectly on GitHub — broken numbered lists, heading hierarchy problems, inconsistent spacing, malformed tables — and fixes what it can automatically.

Never changes your words. Only formatting.

## Usage

Invoke via slash command:

```
/md-linter
```

Or just ask naturally:

- "Check my documents before I push"
- "I just wrote a new policy, check it"
- "My numbered list is rendering wrong"
- "Fix all markdown errors"
- "Set up linting for this repo"

### Slash command options

```
/md-linter:mdlinter [mode] [scope]
```

- **mode**: `check` (default, report only) or `fix` (apply changes)
- **scope**: specific files, a folder, or omit for changed-files-only

Examples:

```
/md-linter:mdlinter                              # check changed files
/md-linter:mdlinter fix                           # fix changed files
/md-linter:mdlinter policies/access-control.md    # check one document
/md-linter:mdlinter fix docs/                     # fix everything in docs/
```

## What it catches

| Issue | Why it matters |
|-------|---------------|
| **Numbered lists breaking apart** | Steps with sub-content (paragraphs, diagrams, code) between them render as separate lists restarting at 1 |
| **Heading hierarchy jumps** | Jumping from h2 to h4 confuses document structure |
| **Spacing inconsistencies** | Extra blank lines, missing blank lines before lists |
| **Malformed tables** | Missing pipes, inconsistent column counts |
| **Bold text as headings** | `**Section**` should be `## Section` |
| **Mermaid diagram fencing** | Malformed fences render as raw text instead of diagrams |
| **GitHub callout typos** | `[!WARINING]` renders as plain text instead of a styled box |

## Workflow

```
Write → Lint → Push → Read
```

1. You write your documents in markdown
2. You run `/md-linter` — it scans only the files you changed
3. It auto-fixes what it can (spacing, blank lines, trailing whitespace)
4. It walks you through anything that needs your attention
5. You push clean, well-formatted documents to GitHub

## How it works

The skill runs a 6-phase workflow:

1. **Setup** — verifies `markdownlint-cli2` is available (via `npx`)
2. **Scan** — lints the scoped files, produces an error inventory
3. **Analyze** — categorizes errors, flags what needs manual attention
4. **Auto-fix** — runs `--fix` for everything markdownlint can handle
5. **Manual fixes** — guides you through remaining issues with reference docs
6. **Verify** — re-runs the linter to confirm everything is clean

Phases 1-3 run in a background subagent to keep your conversation clean. Phases 4-6 are interactive — you approve changes and make decisions.

## Reference guides

The skill includes two reference guides, loaded only when needed:

- **`references/MD029-Fix-Guide.md`** — Ordered list issues. The most common problem in procedural documents: content between numbered steps breaks list continuity. Root cause is always indentation.
- **`references/MD036-Guide.md`** — Bold-text-as-heading issues. Common when writing documents by hand.

## Configuration

Creates `.markdownlint-cli2.jsonc` if none exists:

```json
{
  "config": {
    "MD013": false
  },
  "ignores": []
}
```

MD013 (line length) is disabled by default — long lines in documentation are normal and shouldn't be flagged.

## The cardinal rule

The linter fixes formatting. It does not touch the words you wrote. If a lint rule can only be satisfied by changing what your text says, the skill reports it to you and lets you decide — it will never silently rewrite your content.

## License

MIT — see [LICENSE](LICENSE).

## Acknowledgements

Forked from [s2005/markdown-linter-fixer-skill](https://github.com/s2005/markdown-linter-fixer-skill). Built on [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) by David Anson.

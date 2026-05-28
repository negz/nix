---
name: github-pull-requests
description: Create and manage GitHub pull requests in Nic Cope's style. Use when creating, opening, or drafting PRs, or updating PR descriptions. Uses gh CLI.
compatibility: Requires authenticated gh CLI
---

# Pull Request Style Guide

## When to Use This (vs Other GitHub Skills)

Use **this skill** when creating, editing, or drafting pull requests.

Use **github** for read-only operations (viewing, listing, diffing PRs).

Use **github-issues** when creating or filing issues.

## IMPORTANT: Require Confirmation

**Never run `gh pr create` without explicit user approval.** Always:
1. Draft the PR title and description
2. Show it to the user
3. Wait for confirmation or requested changes
4. Only then create the PR

## Tools

Use the `gh` CLI to create, update, and manage pull requests:

```bash
gh pr create --title "..." --body "..."
gh pr edit --body "..."
gh pr view
gh pr list
```

## Formatting and the gh CLI

**Do not hard-wrap the body at 80 characters.** Unlike commit messages and
scratch docs, PR descriptions render as Markdown on GitHub, which reflows text to
the viewport. Hard wrapping inserts line breaks mid-sentence that look wrong in
the rendered view. Write each paragraph as one continuous line and let GitHub
handle wrapping. Use blank lines between paragraphs.

**Always pass the body via `--body-file`, never `--body`.** PR bodies are full of
backticks (code spans), `$`, and apostrophes. On the command line inside a
double-quoted `--body` string, the shell runs unescaped backticks and `$(...)` as
command substitution and expands `$`, corrupting the body. Escaping and
single-quoting each handle some of these but break on others. Writing the body to
a file sidesteps all of it — use it every time:

```bash
gh pr create --title "..." --body-file /tmp/pr-body.md
```

Or pipe from stdin with a quoted `'EOF'` heredoc, which prevents the shell from
interpreting anything in the body:

```bash
gh pr create --title "..." --body-file - <<'EOF'
Fixes #123

The `Reconcile` method returned early when `spec.forProvider` was nil.
EOF
```

## PR Templates

If the repository has a PR template (`.github/PULL_REQUEST_TEMPLATE.md` or similar), you **must** use it. Check for templates before creating the PR body.

## Required Elements

- Start with issue references: "Fixes #XXXX" or "Closes #XXXX"
- Lead with problem statement, then solution
- Fill checklist completely, strike through irrelevant items with `~text~`

## Content Structure

1. **Issue references** (first line)
2. **Problem statement** (what's broken/missing)
3. **Solution summary** (technical approach)
4. **Implementation details** (architecture, trade-offs)
5. **Migration notes** (if breaking changes)

## Writing Style

- **Technical and precise**: Use exact terminology
- **Problem-focused**: Always explain the underlying issue
- **Honest about complexity**: Acknowledge hacks, limitations, edge cases
- **Proactive**: Direct reviewer attention to complex areas

## What NOT to Do

- **No bragging**: Don't describe changes as "elegant", "robust", "powerful", etc.
- **No table stakes**: Don't mention that you wrote tests, ran linters, or followed other expected practices. The checklist covers this. Focus on *why* and *what*, not proving you did the basics.
- **No marketing speak**: Avoid "This exciting new feature" or similar language
- **No obvious statements**: Don't say "This PR adds X" when the title already says it

## Example Opening

```
Fixes #6719

The CRD-to-MRD converter was converting all CRDs to MRDs, including provider configuration types like `ProviderConfig`, `ClusterProviderConfig`, and `ProviderConfigUsage`. These are not managed resources and should remain as regular CRDs that get installed immediately.

This PR updates the converter to use `isManagedResource()` to identify which CRDs represent actual managed resources. Provider configuration types are excluded from conversion and remain as regular CRDs in the output.
```

## Checklist Guidelines

- Check items that apply: `- [x] Item`
- Strike through irrelevant items: `- [ ] ~Item~`
- Be honest about what was and wasn't done

## Architecture Explanations

When describing complex changes, include:
- How the change fits into existing systems
- What alternatives were considered
- Why this approach was chosen
- Any limitations or trade-offs

## Respectful Communication

- Focus on what's different/improved, never criticize previous implementations
- Use neutral language: "The converter now distinguishes..." not "The old converter was broken"

## Key Principles

1. Be technical, not promotional
2. Explain problems before solutions
3. Acknowledge complexity honestly
4. Focus on "why", not just "what"
5. Use precise, domain-specific terminology

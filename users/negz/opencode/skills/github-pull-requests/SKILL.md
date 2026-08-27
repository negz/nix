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
single-quoting each handle some of these and break on others. Writing the body to
a file avoids the problem, so use it every time:

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
2. **Problem statement** (what's broken or missing)
3. **Solution summary** (technical approach)
4. **Details** (architecture, trade-offs)
5. **Migration notes** (if breaking changes)

The description covers the broad strokes, and skips incidental changes. Where the
branch also has a commit series, the PR body runs shorter than the commit
messages, at roughly a third of the length. Write it once and reuse it, since a
PR description and its commit message usually say the same thing, with only the
wrapping differing. Refer to "this PR" rather than "this commit".

## Writing Style

- **Technical and precise.** Use exact terminology.
- **Problem-focused.** Always explain the underlying issue.
- **Honest about complexity.** Acknowledge hacks, limitations, and edge cases.
- **Proactive.** Direct reviewer attention to the complex areas.
- **Flat.** Write prose rather than sections. Resist giving each commit its own
  `###` heading, and don't reach for bold or headings to look organised.
- **Illustrated.** Trade paragraphs for a worked example. A small but complete
  YAML manifest does more than a paragraph describing it, and long verified
  manifests belong in collapsed blocks.

Run Vale over the body before creating the PR, since the body file is markdown:

```bash
vale /tmp/pr-body.md
```

The **writing-style** skill governs the prose. Cut the draft by 30%, then read it
again and cut more. Never invent rationale.

## What NOT to Do

- **Nothing promotional.** Don't describe changes as "elegant" or "powerful".
- **No table stakes.** Don't mention tests, linters, or other expected practices. The checklist covers it. Focus on why and what, rather than on proving you did the basics.
- **No marketing speak.** Avoid "This exciting new feature" and similar.
- **No obvious statements.** Don't write "This PR adds X" when the title says it.
- **No scope-limiting boilerplate.** Leave out what's deferred or out of scope unless asked.
- **No explaining a linked issue.** The reader can click through for context.

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
- What alternatives you considered
- The reasoning behind the chosen approach
- Any limitations or trade-offs

## Respectful Communication

- Focus on what's different/improved, never criticize previous implementations
<!-- vale off -->
- Use neutral language: "The converter now distinguishes..." not "The old converter was broken"
<!-- vale on -->

## Key Principles

1. Be technical rather than promotional
2. Explain problems before solutions
3. Acknowledge complexity
4. Focus on "why" as much as "what"
5. Use precise, domain-specific terminology
6. Keep it flat and short, at roughly a third of the commit message
7. Show a complete YAML example rather than describing one

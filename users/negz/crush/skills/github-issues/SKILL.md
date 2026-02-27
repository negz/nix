---
name: github-issues
description: Create GitHub issues in Nic Cope's style. Use when opening, creating, or filing issues, bug reports, feature requests, or proposals. Uses gh CLI and respects issue templates.
compatibility: Requires authenticated gh CLI
---

# GitHub Issue Style Guide

## When to Use This (vs Other GitHub Skills)

Use **this skill** when creating or filing issues, bug reports, feature requests,
or proposals.

Use **github** for read-only operations (viewing, listing, searching issues).

Use **github-pull-requests** when creating or editing PRs.

## IMPORTANT: Require Confirmation

**Never run `gh issue create` without explicit user approval.** Always:
1. Draft the issue title and body
2. Show it to the user
3. Wait for confirmation or requested changes
4. Only then create the issue

## Use Issue Templates

Check if the repo has issue templates before drafting:

```bash
ls .github/ISSUE_TEMPLATE/
```

Common templates: `bug_report.md`, `feature_request.md`

Use the template flag when creating:

```bash
gh issue create --template bug_report.md --title "..." --body "..."
```

If templates exist, **you must use one**. Fill out all template sections.

## Creating Issues

```bash
gh issue create --title "..." --body "..."
gh issue create --template <template> --title "..." --body "..."
gh issue create --label bug --title "..." --body "..."
```

## Bug Report Style

Use the repo's bug template sections. Key principles:

- **What happened**: Describe the problem clearly and technically
- **Evidence**: Include logs, error messages, stack traces, code links
- **Root cause**: If known, explain why it happens (link to specific code)
- **Reproduction**: Numbered steps, specific commands, example YAML
- **Environment**: Version, platform, relevant configuration

### Example Bug Report

```markdown
### What happened?

The resolver controller panics when the installed package uses a digest 
reference (e.g., `@sha256:...`) instead of a semver tag.

The function calls `semver.MustParse(insVer)` at 
[`reconciler.go:629`](https://github.com/.../reconciler.go#L629), where 
`insVer` comes from `pref.Identifier()`. When the package reference is a 
digest, `Identifier()` returns `sha256:abc123...`, which is not a valid 
semver string.

### How can we reproduce it?

1. Enable the `EnableAlphaDependencyVersionUpgrades` feature flag
2. Install a Configuration that depends on a Provider
3. Install that Provider using a digest reference
4. The resolver will panic at `semver.MustParse`

### What environment did it happen in?

Crossplane version: main (commit abc1234)
```

## Feature Request / Proposal Style

Use the repo's feature template sections. Key principles:

- **Problem first**: Explain the use case and pain point before proposing solutions
- **Context**: Why does this matter? Who is affected?
- **Prior art**: Reference existing solutions, related issues, or designs
- **Concrete examples**: YAML, code, CLI commands showing the proposed UX
- **Trade-offs**: Acknowledge complexity, alternatives considered

### Example Proposal

```markdown
### What problem are you facing?

Crossplane packages can install other packages as dependencies. You can 
configure a package directly - e.g. its image pull secrets, pull policy. 
Until recently there wasn't any way to configure packages pulled in as 
dependencies though.

We added the `ImageConfig` API to solve this. It's proven useful, so we've 
expanded it to configure more settings. But this creates a complicated 
mental model: when do you use ImageConfig vs package spec?

### How could Crossplane help solve your problem?

I think we should make it possible to configure everything via an ImageConfig.
If you can configure it on a Provider spec, you should be able to configure 
it via an ImageConfig as well.
```

## Key Principles

1. Be technical and specific - link to code, include line numbers
2. Lead with the problem, not the solution
3. Include evidence: logs, examples, reproduction steps
4. Credit others who contributed analysis
5. No marketing language or bragging
6. Fill out all template sections (strike through if N/A)

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

## Formatting and the gh CLI

**Do not hard-wrap the body at 80 characters.** Unlike commit messages and
scratch docs, issue bodies render as Markdown on GitHub, which reflows text to
the viewport. Hard wrapping inserts line breaks mid-sentence that look wrong in
the rendered view. Write each paragraph as one continuous line and let GitHub
handle wrapping. Use blank lines between paragraphs.

**Always pass the body via `--body-file`, never `--body`.** Issue bodies are full
of backticks (code spans like `semver.MustParse`), `$`, and apostrophes. On the
command line inside a double-quoted `--body` string, the shell runs unescaped
backticks and `$(...)` as command substitution and expands `$`, corrupting the
body. Escaping and single-quoting each handle some of these but break on others.
Writing the body to a file avoids the problem, so use it every time:

```bash
gh issue create --title "..." --body-file /tmp/issue-body.md
```

Or pipe from stdin with a quoted `'EOF'` heredoc, which prevents the shell from
interpreting anything in the body:

```bash
gh issue create --title "..." --body-file - <<'EOF'
The resolver panics when it calls `semver.MustParse` on a digest reference.
EOF
```

## Bug Report Style

Use the repo's bug template sections. Key principles:

- **What happened.** Describe the problem clearly and technically.
- **Evidence.** Include the logs, error messages, and code links a reader can't reconstruct.
- **Root cause.** Where known, explain why it happens, and link to the code.
- **Reproduction.** Numbered, copy-pasteable steps with example YAML.
- **Environment.** The versions, platform, and relevant configuration.

### Example Bug Report

```markdown
### What happened?

The resolver controller panics when the installed package uses a digest reference (e.g., `@sha256:...`) instead of a semver tag.

The function calls `semver.MustParse(insVer)` at [`reconciler.go:629`](https://github.com/.../reconciler.go#L629), where `insVer` comes from `pref.Identifier()`. When the package reference is a digest, `Identifier()` returns `sha256:abc123...`, which is not a valid semver string.

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

- **Problem first.** Explain the use case and the pain point before proposing anything.
- **Context.** Why does this matter, and who is affected?
- **Prior art.** Reference existing solutions and related designs.
- **Concrete examples.** The YAML, code, or CLI commands showing the proposed UX.
- **Trade-offs.** Acknowledge the complexity and the alternatives considered.

### Example Proposal

```markdown
### What problem are you facing?

Crossplane packages can install other packages as dependencies. You can configure a package directly - e.g. its image pull secrets, pull policy. Until recently there wasn't any way to configure packages pulled in as dependencies though.

We added the `ImageConfig` API to solve this. It's proven useful, so we've expanded it to configure more settings. But this creates a complicated mental model: when do you use ImageConfig vs package spec?

### How could Crossplane help solve your problem?

I think we should make it possible to configure everything via an ImageConfig. If you can configure it on a Provider spec, you should be able to configure it via an ImageConfig as well.
```

## Scope and Framing

An issue states the problem. It doesn't prescribe the fix.

- Explain why the problem happens without dictating how to solve it. A
  well-framed problem is worth more than a proposed fix, and being prescriptive
  about the code invites the wrong argument.
- Keep an issue scoped to one problem. Where options exist, mention them briefly
  and generally rather than litigating them.
- Leave out a "scope" section and a verdict on what should happen next.
- Don't explain what a linked issue says. The reader can click through.
- Link code through a pinned-commit permalink, so GitHub renders it as a snippet
  rather than a line that drifts.

The issue appears under Nic's name, so it reads as his. Don't add attribution,
co-author lines, or credit he didn't ask for. Credit a colleague's analysis in
prose where it's warranted.

Run Vale over the body before creating the issue, since the body file is
markdown:

```bash
vale /tmp/issue-body.md
```

The **writing-style** skill governs the prose. Cut the draft by 30%, then read it
again and cut more. Never invent rationale.

## Key Principles

1. Be technical and specific, linking to code with line numbers
2. Lead with the problem rather than the solution
3. Include the evidence a reader can't reconstruct
4. State the problem without prescribing the fix
5. No marketing language or bragging
6. Fill out all template sections, striking through what doesn't apply
7. No attribution he didn't ask for

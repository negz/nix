---
name: github
description: Interact with GitHub using the gh CLI. Use when viewing PRs, checking CI status, reviewing code, listing issues, or any GitHub operation. Prefer gh over web fetching.
compatibility: Requires authenticated gh CLI
---

# Working with GitHub

## When to Use This (vs Other GitHub Skills)

Use **this skill** for read-only GitHub operations: viewing PRs, checking CI,
listing issues, reviewing code, exploring repos.

Use **github-pull-requests** when creating or editing PRs.

Use **github-issues** when creating or filing issues.

## Rules

- **Always use `gh`** — never use web fetch tools for GitHub operations.
- **Never submit reviews.** You may analyze and summarize, but do not run
  `gh pr review` (with `--approve`, `--comment`, or `--request-changes`) or
  `gh pr comment`. The user will write and submit their own review comments.

## Key Principles

1. Use `gh` for all GitHub operations — it's authenticated and structured
2. Read-only by default — never submit reviews, comments, or approvals
3. Summarize what you find — the user wants analysis, not raw output
4. Use `gh pr checkout` to explore code locally when the diff isn't enough

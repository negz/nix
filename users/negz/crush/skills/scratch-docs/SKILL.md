---
name: scratch-docs
description: Draft, publish, and iterate on markdown documents in the upbound/scratch repo. Use when the user wants to draft a document (PRD, design, exploration, R&D notes), open a PR for review, read review comments, or iterate on a scratch document. Also use when the user mentions their scratch repo.
compatibility: Requires authenticated gh CLI and git
---

# Scratch Documents

Draft markdown documents in `upbound/scratch` and share them for review via
GitHub PRs.

## When to Use This (vs Other Skills)

Use **this skill** when drafting, publishing, or iterating on scratch documents
— PRDs, design explorations, R&D notes, proposals.

Use **github-pull-requests** when creating PRs in other repos.

Use **git-commits** for commit style (this skill defers to it).

## Repo

- **GitHub**: `upbound/scratch` (private)
- **Local path**: `~/control/upbound/scratch`

## File Layout

- **Start flat.** A new document is `topic-name.md` at the repo root.
- **Promote to a directory** when a topic grows beyond one file. Move
  `topic-name.md` to `topic-name/README.md` and add sibling files.
  `README.md` is always the entry point — GitHub renders it when browsing a
  directory.
- **Kebab-case everything.** `xpkg-cache.md`, `imageconfig-rewrite.md`, etc.
- **No date prefixes or categories.** PR history provides timeline context.

## Two Modes: Drafting vs. Sharing

All documents live in the scratch repo on branches. Most of the time, a
document is just being drafted — the user is working with the LLM to explore
an idea. Sharing (opening a PR) is a separate, explicit step.

### Drafting

Draft on a branch. Commit locally. Don't push or open a PR unless asked.

1. Pull latest main:
   ```bash
   cd ~/control/upbound/scratch && git checkout main && git pull
   ```
2. Create a branch named after the document:
   ```bash
   git checkout -b topic-name
   ```
3. Write the document following the file layout conventions above.
4. Commit locally. Defer to the **git-commits** skill for commit style.

Drafting should feel lightweight. No need to push, no need to think about
reviewers. The branch is just a place to put the work so it has git history
and doesn't get lost.

### Sharing

When the user asks to share a document — "open a PR", "get feedback on this",
"share this with X" — push the branch and open a PR.

```bash
git push -u origin topic-name
```

The repo has a PR template with two sections: **Context** and **Feedback
wanted**. Fill both in.

- **Title** is the document title.
- **Context** is one or two sentences on what the document is. Note the
  document's maturity — e.g. if it's LLM-generated and hasn't been personally
  reviewed yet, say so. This sets reviewer expectations.
- **Feedback wanted** describes what kind of review is useful. Match the ask to
  the document's maturity:
  - Early drafts / strawmen: "Directional — does the overall shape make sense?"
  - Iterated drafts: "Detailed — poke holes in the technical design."
  - Specific questions: "See open questions at the end of the doc."
- No checklist, no issue references.

Draft the PR description and show it to the user for approval before creating.

```bash
gh pr create --title "Document title" --body "..."
```

Add reviewers if the user specifies them:
```bash
gh pr edit --add-reviewer handle1,handle2
```

## Reading Review Comments

When the user asks to check for or react to review comments:

1. **List PR comments and reviews:**
   ```bash
   # PR-level comments
   gh pr view <number> --comments

   # Inline review comments (these are the most useful)
   gh api repos/upbound/scratch/pulls/<number>/comments
   ```

2. **Summarize the feedback** — group by theme, highlight actionable items,
   note any conflicting opinions.

3. **Ask the user how to proceed** if feedback is ambiguous or contradictory.
   Otherwise, proceed to iterate.

## Iterating on a Document

After reading review comments:

1. Make sure the branch is checked out and up to date:
   ```bash
   cd ~/control/upbound/scratch && git checkout topic-name && git pull
   ```
2. Edit the document to address feedback.
3. Commit and push. Each round of iteration is a separate commit so reviewers
   can see what changed.
4. Optionally reply to specific review threads if the changes warrant
   explanation (use `gh api` to reply to review comments).

## Key Principles

1. The scratch repo is for early-stage ideas — keep ceremony low
2. Draft on branches, only push and open PRs when asked to share
3. One branch and one PR per document
4. Start flat, promote to a directory only when needed
5. Defer to git-commits and github-pull-requests skills for style
6. Each review iteration is a separate commit for clear diffs
7. Set reviewer expectations — note maturity level in the PR description
8. Match the feedback ask to the document's maturity
9. Documents that mature can graduate to `upbound/arch` or `crossplane/crossplane`

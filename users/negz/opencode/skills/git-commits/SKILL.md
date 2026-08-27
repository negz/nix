---
name: git-commits
description: Write git commits in Nic Cope's style. Use when creating commits, staging changes for commit, or when the user asks to commit. Includes Signed-off-by requirements and problem-first messaging.
---

# Git Commit Style Guide

## IMPORTANT: Require Confirmation

**Never run `git commit` without explicit user approval.** Always:
1. Draft the commit message
2. Show it to the user
3. Wait for confirmation or requested changes
4. Only then create the commit

## Required Format
- **Always** include `Signed-off-by: Nic Cope <nicc@rk0n.org>`
- Subject line, 50-80 characters, imperative mood
- Body wrapped at 80 characters, explaining the "why"
- No other trailers unless asked. Leave out `Reported-by`, `Co-authored-by`, and
  any AI attribution.
- No typed prefix. Don't write `feat:`, `fix:`, or `chore:`.

## Subject Line Patterns
- Start with an imperative verb. "Fix", "Add", "Update", "Use", "Support"
- Be specific and technical. "Fix CRD-to-MRD converter to preserve provider configuration CRDs"
- Include scope when helpful. "Use WIRE_JSON level buf breaking change detection"
- Avoid vague terms. Write "Fix composed resource names containing invalid characters" rather than "Update code"
- Name the thing the commit accomplishes, and let the mechanics follow from it. A
  commit that swaps a DaemonSet for something else is framed as "Detect readiness
  correctly", with the removal noted as part of that.

## Body Content
- **Problem first.** Explain what was wrong or missing.
- **Solution.** Describe it in natural language, using something like "This commit replaces…" or "This change updates…" rather than bare imperatives.
- **Technical details.** Include the specifics.
- **Behaviour changes.** Show before/after examples where relevant.
- **Context.** Reference related issues, design decisions, and trade-offs. Include the real motivating context, such as a reviewer's original concern and why the commit goes this way instead.
- **Nothing promotional.** Don't call things "elegant" or "powerful".
- **No table stakes.** Don't mention tests, formatting, or linting fixes. Focus on what the code does rather than on proving you followed the basics.
- **Never invent rationale.** A diff shows what changed, and not why. Ask when you don't know, rather than supplying a plausible reason.

For a documentation change, mirror the document's own summary rather than writing
a fresh description.

## Scope and Grouping

Each commit is one self-contained logical layer. The history reads as designed
layers, and never as a record of how the work unfolded.

- Fold review fixes into the commit that introduced the problem, or into a
  targeted commit naming the specific fix. Never write "address review feedback",
  "fix review", "fix tests", or a catch-all like "issues found during E2E".
- Decide grouping by whether one coherent message covers the whole change. Where
  you can't write that message, the changes belong in separate commits.
- Keep the message proportional to the diff, and not to the order the work
  happened in. A session's final tweak shouldn't occupy half the message.
- Size the message to the change. A small fix warrants a short paragraph.

Before proposing, check whether reordering or squashing would make the series
tell a more coherent story. Expect to walk through a series one commit at a time
for approval.

## Writing

The **writing-style** skill governs the prose. Cut the draft by 30%, then read it
again and cut more.

## Example

```
Fix XRD controller restart to detect all spec changes

When XRD spec fields change, the XR controller doesn't always restart
automatically. Users must manually restart the Crossplane deployment for
some changes to take effect, as reported in issue #6736.

The existing restart logic only detected referenceable version changes.
This missed other spec changes like connection details modifications.

This commit replaces the referenceable version based detection with
generation-based controller restart detection using the existing
condition system. The ControllerNeedsRestart() helper checks if the
WatchingComposite condition's observedGeneration differs from the
current metadata.generation.

Fixes #6736.

Signed-off-by: Nic Cope <nicc@rk0n.org>
```

## Key Principles

1. Be technical rather than promotional
2. Explain problems before solutions
3. Acknowledge complexity
4. Focus on "why" as much as "what"
5. Never invent a rationale you don't know
6. Use precise, domain-specific terminology
7. Describe previous work in neutral language
8. One logical layer per commit, with review fixes folded into it
9. Keep the message proportional to the diff

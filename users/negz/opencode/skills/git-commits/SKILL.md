---
name: git-commits
description: Write git commits in Nic Cope's style, and decide when to commit and what belongs in each one. Use when creating or amending commits, when staging changes, or whenever you finish a unit of work. Also use when the user asks to commit. Includes Signed-off-by requirements and problem-first messaging.
---

# Git Commit Style Guide

## When to Commit

Commit finished work as you go. Don't ask whether to commit, and don't show the
message first. Write it, commit it, and report the subject line. Waiting for
approval costs a round trip that the message rarely needs.

Commit once a logical unit of work is complete and working, which is usually
several edits in rather than after each one. A commit that leaves the tree
broken isn't a smaller commit, it's half of one, so run the project's own checks
first.

Don't commit while he's still deciding what the work is. A question is a
question, and a half-finished edit is not a unit of work.

Where something in the change needs a decision rather than a message, ask about
that. The usual case is a commit that would record a rationale you're guessing
at. Ask why instead of committing and hoping.

Stage the paths you touched, by name. `git add -A` sweeps up whatever else sits
in the tree, which turns one commit into two changes.

## Amending

Work arrives in passes. He asks for a change, reads it, then asks for another
that turns out to be the first change told better. A commit per pass gives a
history of how the work unfolded, which is exactly what the history should hide.

So before committing, read HEAD's subject and diff. Where the new change
continues that commit's story rather than starting a new one, amend it, and
rewrite the message to cover the amended whole. A subject that fitted the first
pass rarely fits all three.

Amend only when all of these hold:

- It's HEAD. Never rewrite further back unless he asks.
- It's unpushed. Check `git status -sb` rather than assuming.
- It's yours, from this session.
- The new change serves the same goal, and not merely the same file. Two
  unrelated edits to one file are two commits.

The test is the message, as it is for grouping. Where one coherent message
covers the old commit and the new change together, amend. Where the honest
message for the new change alone would open with "also" or "actually, make that",
that's the same signal.

Rewriting a message means checking it again, against the whole amended diff.

## Write as Nic, Not About Him

Git records the commit as authored by Nic Cope, so the message is his voice.
Write in first person, or drop the pronoun. Never refer to him in the third
person, which reads to everyone else as the author talking about himself:

- Wrong: "Nic compared 16 rewrites against the originals."
- Right: "I compared 16 rewrites against the originals."
- Also right: "Comparing 16 rewrites against the originals showed…"

The same holds for anything else published under his name, including PR
descriptions, issue bodies, and design docs.

Note that this inverts inside the skill files themselves. Those describe Nic to
an agent, so third person belongs there and nowhere that carries his byline.

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
  commit that swaps a DaemonSet for something else takes the subject "Detect readiness
  correctly", with the removal noted as part of that.

## Body Content

**One paragraph is the default.** What was wrong, then what the change does about
it. That covers most commits. A trivial change needs a subject line and nothing
else.

Add a second paragraph where the diff hides a trade-off, or where a reader can't
recover the context from the code. Going beyond that is rare, and usually means
you should have split the change.

What goes in:

- **Problem first.** What was wrong or missing.
- **Solution.** Describe it in natural language, using something like "This commit replaces…" rather than a bare imperative.
- **Context the diff doesn't hold.** A trade-off, a constraint that forced the approach, or a reviewer's concern and why the commit goes this way instead. Reference the issue.

What to leave out:

- Anything the subject line already said.
- A hunk-by-hunk account. Describe the change, and let the diff show the edits.
- Detail proportional to your effort rather than to the reader's need. A hard-won
  one-line fix still gets one line.
- Table stakes. Readers expect tests, formatting, and linting, so reporting them
  is noise.
- Promotional language. Nothing is "elegant" or "powerful".
- **Invented rationale.** A diff shows what changed, and not why. Ask when you
  don't know, rather than supplying a plausible reason.

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

Mechanical changes belong in their own commits, so a reader can skim them and
study the rest:

- Generated code goes in its own commit, following the commit that changes the
  generator or its input.
- Copy a file in one commit, then edit the copy in the next. Git then shows the
  edit as a diff, instead of burying it inside a wholly new file. Moves and
  renames work the same way.
- A commit either moves code or changes what it does, and never both.
- Formatting and lint passes stand alone.
- Dependency bumps stand alone, ahead of the code that needs them.

Order the series so each commit builds on the last: prerequisites, then the
change they enable, then the cleanup. Someone reading only the subject lines
should get the argument. Someone checking out a commit from the middle should
get a tree that works.

Before committing a series, check whether reordering or squashing would make it
tell a more coherent story.

## Writing

The **writing-style** skill governs the prose, and its cutting passes apply here.
Write the body, cut a third of it, then read what's left and cut again. A message
that survives both passes is about the right length.

Most of the flab comes from explaining the change twice at different altitudes,
or from justifying a decision no reader would question.

## Check the Message Against the Diff

You draft the message with the whole session in your head, which is the one
position from which you can't judge it. You can't tell which parts a reader could
infer from the change, and you can't see where you supplied a reason from memory
rather than from the diff. A reader with only the diff and the message catches both.

So for anything beyond a mechanical change, dispatch a subagent before
committing. Give it the staged diff and the drafted message and nothing else, no
session context and no explanation. Ask it three questions:

1. Which claims in this message does this diff not support?
2. What does this message say that the diff already shows?
3. Which sentences don't follow from the sentences before them, or from the diff?

The first two questions check sentences one at a time, so a message where every
sentence holds up but the joins between them don't survives both. The third
catches a cause the diff doesn't establish, a conclusion the stated problem
doesn't reach, and two sentences that contradict each other.

The reviewer can recommend cuts and flag unsupported claims. It cannot recommend
additions. A reviewer invited to say what's missing will always find something,
the message grows every round, and you've rebuilt the problem this exists to
catch. Keep the brief to those three questions.

Extending the brief later means naming an operation the reviewer can perform, as
those three do. "Is this message coherent?" asks for a verdict instead, and a
reviewer holding a verdict either waves the message through or goes looking for
what's missing.

Act on what comes back, and don't relay it. Where the reviewer says a claim isn't
in the diff, either cut the claim or ask why, since that's the case where a
guessed rationale would otherwise reach the permanent record.

Skip this for a rename, a version bump, or a formatting pass. Run it whenever the
message explains why.

## Examples

The common case, one paragraph:

```
Use unstable Home Assistant package on roach

Home Assistant releases monthly and the stable nixpkgs channel is
currently 5 releases behind (2025.11.3 vs 2026.4.3). Using unstable
keeps HA current with security patches, new integrations, and device
compatibility. This matches the existing pattern for Plex on roach.

Signed-off-by: Nic Cope <nicc@rk0n.org>
```

A second paragraph, where the reader needs the mechanism as well as the problem:

```
Fix XRD controller restart to detect all spec changes

When XRD spec fields change, the XR controller doesn't always restart
automatically, so users have to restart the Crossplane deployment by
hand for some changes to take effect. The existing logic only detected
referenceable version changes, and missed everything else in the spec.

This commit replaces that with generation-based restart detection. The
ControllerNeedsRestart() helper compares the WatchingComposite
condition's observedGeneration against the current metadata.generation.

Fixes #6736.

Signed-off-by: Nic Cope <nicc@rk0n.org>
```

A mechanical change gets a subject line and a sign-off, with no body.

## Key Principles

1. One paragraph by default, and a subject line alone for a mechanical change
2. Commit finished work as you go, without asking and without showing the message
3. Explain problems before solutions
4. Focus on "why" as much as "what"
5. Never invent a rationale you don't know
6. Be technical rather than promotional
7. Use precise, domain-specific terminology
8. Describe previous work in neutral language
9. One logical layer per commit, with review fixes folded into it
10. Amend HEAD where the change continues it, rather than stacking a second commit
11. Have a subagent check the message against the diff, and let it cut only
12. Check the joins between sentences, not just the sentences

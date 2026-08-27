---
name: fix-friction
description: Remove recurring friction between Nic and an agent by mining chat transcripts for corrections he makes repeatedly, then fixing the cause with whatever mechanism fits, such as a linter rule, a skill, AGENTS.md, opencode configuration, or a subagent check. Use when Nic asks what he keeps correcting, or wants to harvest or mine past sessions. Also use when he wants a skill built or tuned from real feedback, or wants to improve how he and an agent work together. He may say he repeats himself. For a one-off annoyance, fix that directly instead.
---

# Fix Friction

Find what Nic corrects repeatedly, then remove the cause. The evidence is in
the opencode transcripts, and the remedy is whichever mechanism enforces the
lesson most reliably.

Run this process rather than reasoning it out, because an agent's memory of what
it gets wrong is unreliable in a specific direction: it under-reports, and it
defends the output it produced. The transcripts hold hundreds of corrections that
no amount of introspection recovers.

## When to Use This (vs skill-creator)

Use **skill-creator** to write or edit a skill whose content you already know.

Use **this skill** to work out what that content should be, and whether a skill
is even the right mechanism. It ends by calling skill-creator, editing AGENTS.md,
or changing configuration, depending on what the evidence says.

## The Process

Scope, harvest, read in parallel, diagnose, choose a mechanism, build, validate.
That order matters, because diagnosing before harvesting produces a guess, and
choosing a mechanism before diagnosing produces a skill nobody needed.

## 1. Scope

Pick a domain narrow enough that the corrections share a cause. "How I write
design docs" works. "How I work" doesn't.

Scope a corpus in one of these ways, depending on the domain:

- **By artifact.** Sessions that edited a matching file. Design docs are
  `design/*.md`, Go review feedback is `*.go`, and so on. The sharpest scoping,
  because the artifact identifies the domain.
- **By repository.** Every session in one or more working directories. Use this
  where the domain is a project rather than a file type.
- **By signal.** Messages containing correction markers, for domains with no
  artifact at all. Turn-level interaction feedback belongs here, since "you're too
  verbose" attaches to no file.

Confirm the scope with Nic before harvesting. Getting it wrong wastes the
expensive phase.

## 2. Harvest

Read [references/corpus.md](references/corpus.md) for the database schema, the
queries for each scoping mode, and the chunking recipe.

The mechanics matter less than what follows.

**Check attribution before drawing conclusions.** A document in a repo is rarely
purely Nic's writing. It's often an agent's draft that he copy edited, which
inverts what a surviving defect means: it survived his attention rather than
representing his preference. Ask who wrote the first draft before treating a
document as ground truth.

**Watch for pasted content.** His messages contain quoted files, diffs, and error
output. Measuring word frequency across raw messages measures the files he
pasted. Deduplicate and separate his prose from what he quoted before counting
anything.

## 3. Read in Parallel

A five month corpus runs to megabytes, so no context holds it all. Split at
session boundaries into balanced chunks and dispatch one subagent per chunk.

The brief needs two constraints that a subagent won't assume. Ask for recall
ahead of brevity, and name what to exclude, or it returns every technical
correction alongside the ones you want.

Brief each subagent to return:

- Verbatim quotes, each with its session and date.
- One line per quote on what it implies.
- The recurring themes, with rough counts.

## 4. Diagnose

Rank findings by frequency and by sharpness. They disagree, and sharpness
usually wins. In the writing corpus, length drew 80 corrections and reactive
framing drew 10, but the reactive framing rule proved more valuable, because
frequency measures how often an agent errs while sharpness measures how much the
error costs.

Then work out why each correction recurs, because the three causes need different
fixes:

**Nothing covers it.** The straightforward case. Write something.

**Something covers it and is wrong.** Check this first, because it's the most
common and the least obvious. Guidance that licenses the corrected behaviour is
worse than no guidance. The writing skill told an agent to "let the complexity of
the topic determine the length" while length was the most corrected thing
across five months. Read the existing guidance against the corpus and look for
passages that permit what Nic keeps fixing.

**Something covers it, is right, and never loads.** A skill that doesn't trigger
can't help. Rewriting its body changes nothing, so fix the description instead.
Suspect this where the guidance is already correct and specific.

## 5. Choose the Mechanism

Prefer the most deterministic mechanism that can carry the lesson. An agent can
ignore an instruction. It can't ignore a failing check.

| Lesson | Mechanism |
| --- | --- |
| Mechanically detectable in text | A linter rule, such as Vale |
| Detectable by running something | A flake check, test, or formatter |
| Needs judgment in context | A skill |
| Applies to every task regardless of context | AGENTS.md or global instructions |
| Blocked by tooling rather than knowledge | opencode configuration |
| The acting agent structurally can't see it | A subagent with fresh context |
| A deterministic sequence repeated often | A script or an opencode plugin |

Read [references/mechanisms.md](references/mechanisms.md) for what each one costs
and where each lives.

Worked examples from the writing calibration:

- "Don't use decorative em dashes" became a Vale rule rather than a sentence in a
  skill, because a regex applies mechanically where prose guidance applies when noticed.
- "Don't invent rationale" stayed in a skill, because detecting a fabricated
  reason needs the diff, the session, and judgment.
- "Write commits in my voice" went into the commit skill, and would suit
  AGENTS.md as well, since it holds for every commit in every repo.
- "The linter has no config outside the editor" was a configuration fix, and no
  amount of instruction would have substituted.
- "You can't see your own reactive framing" became a subagent brief, because the
  drafting agent is the one party structurally unable to notice.

One finding often needs two mechanisms. Vale holds the em dash rule, and the
skill explains why it matters, so an agent meeting the alert understands it.

## 6. Build

Hand skill work to **skill-creator**. Put the delta first: an agent reading only
the first screen should meet the corrective pressure rather than a description of
the target. Move reference material into `references/` and keep the main file to
instructions.

Where the corpus produced a verbatim quote that states the rule better than you
can, quote Nic directly. His phrasing has an authority that paraphrase loses.

## 7. Validate

The designs below run in order of value per unit of effort. Read
[references/validation.md](references/validation.md) for the briefs.

**Blind preference test.** Sample real flagged phrases from real documents,
propose a rewrite for each, and ask Nic which he prefers without saying which
side you favour. Cheapest and most decisive. In the writing calibration it
reversed a conclusion that two earlier tests had missed.

**A/B against the old guidance.** Same task, old version against new, fresh
subagents, byte-identical input verified by checksum. Don't tell either subagent
which rule is under test. Count what you can, such as word count and linter
alerts. Read the rest.

**Trap replay.** Reproduce a known historical failure from the corpus, feed the
same input and the same objection, and check whether the new guidance changes the
outcome. This is the only test that proves a judgment rule works, since judgment
rules resist counting.

Sample across everything, including the rules you believe are noise. Your
assessment of which findings are false positives is the least reliable input to
this process. See the pitfalls below.

## Pitfalls

**Your judgment about your own output is the weak link.** In the writing
calibration an agent rated 37 of 47 linter alerts as false positives, then Nic
preferred the linter-driven rewrite in 14 of 16 blind comparisons and never
preferred the original. The same agent defended one phrasing as deliberate craft
and Nic said it read as obviously machine-written. Never let the agent's verdict
stand where you can measure Nic's preference instead.

**Don't pre-filter the sample.** Presenting only the findings you consider valid
hides exactly the cases where you're wrong.

**Rigour doesn't rescue the wrong question.** One measurement in the writing
calibration compared a word's frequency between Nic and an agent to three
decimal places. The frequencies matched, and the real distinction was which
direction the word pointed, which no frequency measurement reaches. Ask whether
the number would change the decision before computing it.

**Validate against the committed state, not your memory of it.** Working-tree state and
intermediate drafts aren't history. Check what the committed artifact
records before describing a change to it.

## Do Not

- Don't write a skill for a lesson a linter can enforce.
- Don't harvest without confirming the scope, since the reading phase is the
  expensive one.
- Don't report a subagent's findings to Nic unfiltered. Synthesise them, and say
  where they disagree.
- Don't stop at the first mechanism that could work. Ask whether a more
  deterministic one exists.
- Don't treat a document in a repo as Nic's voice without checking who drafted
  it.

## Key Principles

1. Harvest evidence rather than recalling it, because recall under-reports
2. Suspect existing guidance before suspecting missing guidance
3. A correction that recurs despite correct guidance is a triggering problem
4. Prefer the most deterministic mechanism that can carry the lesson
5. Rank by sharpness as well as frequency
6. Quote Nic verbatim where his phrasing states the rule most clearly
7. Measure Nic's preference instead of asserting your own
8. Sample everything, including what you think is noise
9. Prove judgment rules by replaying a known failure
10. Check attribution before treating any document as ground truth

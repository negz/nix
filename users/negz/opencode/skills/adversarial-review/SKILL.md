---
name: adversarial-review
description: >-
  Review non-trivial code changes in a fresh context before committing. Use
  before committing new features, non-trivial bug fixes, refactors, or any
  change where correctness matters. Also use when the user asks for a review or
  sanity check. Do not use for typo fixes, doc changes, or purely mechanical
  changes like renames.
---

# Adversarial Review

Two lenses in one pass. Correctness against a contract is the first. Craft is
the second, meaning naming, simplicity, consistency, and whether the change is
over-engineered. Don't make the user ask for the second one separately.

The mechanism is a subagent's fresh context, not an instruction to be careful.
The agent that wrote the code reads it through the lens of its own intent, so
"please double-check your work" doesn't work.

Load whichever language skills fit the diff. They hold the conventions a craft
finding has to cite: `go-code-factoring`, `python-code-factoring`,
`go-unit-tests`, `krm-api-design`.

## The Process

### Extract

Prepare two things for the reviewer:

- **The artifact.** The code diff, or the full files that changed. Concrete, not
  summarised.
- **The contract.** What the code must do, pulled from the user's request, any
  design doc, the function signatures, the tests, or the API spec. State it as
  requirements, not as a narrative of what you did.

Do not pass the reviewer your reasoning, your design rationale, or your decision
history. Handing over your conclusion biases the reviewer toward agreement.

### Doubt

Dispatch a subagent (the Task tool) with the artifact and the contract. The
reviewer's job is adversarial: assume the author is overconfident, and find what
is wrong.

The prompt needs the artifact and the contract, plus:

- An instruction to look for correctness bugs, contract violations, unhandled
  edge cases, uncovered error paths, API misuse, and unvalidated assumptions
- The checks below, which need the repository rather than just the diff
- The craft brief below
- An instruction to classify each finding by severity:
  - **Critical.** Breaks correctness or violates the contract
  - **Issue.** A problem, but not a blocker
  - **Nit.** Style or preference, not worth changing
  - **FYI.** An observation, no action needed

#### Checks that need the whole repository

The checks above look at the diff. These look at what the diff should have
touched and didn't, the class of defect the authoring agent is worst placed to
catch. Give the reviewer the repository, not just the diff.

- **Superseded code left behind.** Does the change fix a root cause while
  leaving the workaround in place? Replace a mechanism while leaving what it
  replaced? Remove the last consumer of a field, parameter or branch without
  removing the thing itself?
- **The fix applied to one instance of a class.** Is the same bug in the sibling
  code path, the other provider, the other backend, the parallel
  implementation? Is the same smell elsewhere in the diff, in the spot nobody
  pointed at?
- **Machinery added under review pressure.** Guards for cases that can't occur,
  suppressions and ignore comments, defensive clones, a hardcoded status, a
  schema weakened to dodge an implementation problem. For each, ask what breaks
  if it isn't there. Anything added to satisfy a reviewer's hypothetical rather
  than an observed failure is a finding.
- **Tests that can't fail.** Does any expected value come from calling the code
  under test? Does a case's fixture actually set up the condition its name
  claims? Would the test still pass if the change were reverted?
- **Claims in comments and docs.** Does a comment describe an invariant nothing
  enforces, or behaviour a rewrite has since changed? Does a docstring describe
  what the function was meant to do rather than what it does?

#### The craft brief

Naming, simplicity and consistency catch the most, so review those first.

- **Naming.** Is each new identifier precise? Could it be confused with an
  adjacent concept? Does it match the convention's intent?
- **Simplicity.** The question, literally, is "do we need this?" Flag redundant
  guards, dead or no-op branches, unused flexibility, bespoke reimplementations
  of solved problems, and deep nesting an early return would flatten. If
  removing it loses nothing, it goes. Simplest *correct*, which is not the same
  as easiest.
- **Consistency.** Does the change solve the same problem the same way
  throughout? Does it match how the repo already does this, and if it diverges,
  is there a comment saying why? Look for asymmetry: when a new type models one
  thing a certain way, the sibling thing usually should too.
- **Comments and docs.** Do they explain why rather than what? Does any comment
  narrate the change rather than describe the current state?

### Reconcile

You are the orchestrator. Evaluate each finding rather than rubber-stamping it,
because acting on every finding is the same failure mode as ignoring them all.

- **Critical or Issue.** Fix it.
- **Nit.** Fix if cheap, skip if not. Don't churn on style.
- **FYI.** Acknowledge and move on.
- **Misread.** The reviewer misunderstood the contract. Discard it. A reviewer
  with no authoring context will sometimes get the requirements wrong, which is
  the cost of the independence that makes it useful.

After fixing Critical or Issue findings, re-run whatever verification applies
(tests, build, linter) before proceeding. A fix that hasn't been verified is a
claim, not a result.

### Stop

One review cycle is the default. Run a second only if the first produced
Critical findings that forced a rework, to confirm the rework didn't introduce
new problems. Never run more than two.

If Critical findings persist after two cycles, the problem is likely in the
design rather than the implementation. Stop and surface it to the user.

## When You Can't Dispatch a Subagent

Where the Task tool isn't available, such as when this skill triggers while you
are already running as a subagent, fall back to a degraded self-review: a
clearly separated pass that ignores your earlier reasoning and works from the
artifact and the contract alone, with the same adversarial framing. Flag the
result as degraded, because same-context review carries the blind spots a fresh
reviewer wouldn't.

## What the Reviewer Should Not Do

Scope the reviewer tightly. It should not:

- **Suggest alternative architectures.** The design is decided. Craft findings
  are about how this implementation reads, not whether a different approach
  would have been better. Where the change really does have design weight,
  surface that to the user rather than burying it in a review finding.
- **Propose new features or scope additions.** The contract is the contract.
  Gold-plating is not a review finding.
- **Report a convention violation without checking the convention.** An
  in-repo pattern may be unreviewed agent output. Cite the source, or say the
  finding rests on precedent alone.

[references/findings.md](references/findings.md) has real findings and what Nic
did with each, including the ones he declined and why. Read it before acting on
a report.

A reviewer prompted to find gaps will usually report some, even when the work is
sound. It is as capable of asking for an unnecessary guard as the author was.
Reconcile, don't obey.

## What a Review Won't Catch

A checklist catches craft, not system design. It won't reliably tell you whether
this should be a separate subcommand, whether the coupling belongs, or whether
the framework is the right one. Neither will it catch correctness that depends
on knowing how an external API behaves.

Where the change carries real design weight, say so to the user rather than
letting the review imply the question is settled.

## Anti-Rationalizations

| Rationalization | Reality |
|---|---|
| "I'm confident this is correct" | Confidence is highest right after authoring, in the same context that wrote the code. |
| "The tests pass, so it's fine" | Tests verify the behaviours you thought to test. Review catches the ones you didn't. |
| "This change is small enough to skip review" | Small changes cause large outages, and reviewing a small change is quick. |
| "Review will just slow things down" | Catching a bug before commit is faster than debugging it after. |

## Key Principles

1. The reviewer gets the artifact and the contract, never the authoring rationale
2. Fresh context is the mechanism. "Review your own work" in the same session doesn't work
3. Give the reviewer the repository, so it can check what the diff should have touched
4. Classify findings by severity. Fix Critical and Issue, don't churn on Nits
5. One cycle by default, two max, then escalate to the user
6. Correctness against the contract and craft, in one pass
7. Cite a convention's source rather than asserting a preference

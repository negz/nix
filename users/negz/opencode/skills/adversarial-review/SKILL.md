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

## When to Use This Skill

Use this skill before committing non-trivial code changes:

- New features
- Non-trivial bug fixes
- Refactors that change behavior or structure
- API or data model changes
- Any change where correctness matters

Also use it when the user explicitly asks for a review or a sanity check.

Do not use it for typos, doc-only changes, mechanical renames or file moves, or
when the user explicitly says to skip review. The review has a cost; spend it
where correctness is actually at stake.

## Why Fresh Context Matters

The agent that wrote the code is biased by its own reasoning. It has seen the
problem evolve, considered and rejected alternatives, and built up conviction
that the current approach is correct. Self-review in the same context is
confirmation bias in action — the agent reads the code through the lens of its
own intent, not the contract it was supposed to fulfill.

A reviewer in a fresh context has no memory of the authoring process. It sees
only the artifact and the spec. This is structurally different from "please
double-check your work," which doesn't work: same context, same blind spots.
The mechanism here is the fresh context, not the instruction to be careful.

## The Process

Four steps: EXTRACT, DOUBT, RECONCILE, STOP.

### Extract

Prepare two things for the reviewer:

- **The artifact** — the code diff, or the full files that changed. Concrete,
  not summarized. The reviewer needs to see the actual code.
- **The contract** — what the code is supposed to do. Pull this from the user's
  request, any design doc, the function signatures, the tests, or the API spec.
  State it as requirements, not as a narrative of what you did.

Do not pass the reviewer your reasoning, your design rationale, or your decision
history. The reviewer should evaluate the artifact against the contract, not
against your justification for it. Handing over your conclusion biases the
reviewer toward agreement.

### Doubt

Dispatch a subagent (the Task tool) with the artifact and the contract. The
reviewer's job is adversarial: assume the author is overconfident, and find what
is wrong.

The prompt to the reviewer should include:

- The artifact (diff or files)
- The contract (requirements)
- An instruction to look for: correctness bugs, contract violations, edge cases
  not handled, error paths not covered, API misuse, and assumptions that aren't
  validated
- An instruction to classify each finding by severity:
  - **Critical** — breaks correctness or violates the contract
  - **Issue** — a real problem, but not a blocker
  - **Nit** — style or preference, not worth changing
  - **FYI** — an observation, no action needed

### Reconcile

You are the orchestrator. Evaluate each finding rather than rubber-stamping it —
acting on every finding is the same failure mode as ignoring them all.

- **Critical / Issue** — Fix it. This is what the review exists to catch.
- **Nit** — Fix if cheap, skip if not. Don't churn on style.
- **FYI** — Acknowledge and move on.
- **Misread** — The reviewer misunderstood the contract. Discard it. This is
  common and expected; a reviewer with no authoring context will sometimes get
  the requirements wrong. That's the cost of the independence that makes it
  useful.

After fixing Critical or Issue findings, re-run whatever verification applies —
tests, build, linter — before proceeding. A fix that hasn't been verified is a
claim, not a result.

### Stop

One review cycle is the default. Run a second cycle only if the first produced
Critical findings that required significant rework — you want to confirm the
rework didn't introduce new problems. Never run more than two cycles.

If Critical findings persist after two cycles, the problem is likely in the
design, not the implementation. Stop and surface it to the user rather than
iterating further.

## When You Can't Dispatch a Subagent

This skill relies on the Task tool to get a fresh context. If that isn't
available — for instance, when this skill triggers while you are already running
as a subagent — fall back to a degraded self-review: start a clearly separated
pass that ignores your earlier reasoning, work only from the artifact and the
contract, and apply the same adversarial framing. Flag the result as degraded,
because same-context review carries the blind spots a fresh reviewer wouldn't.
Prefer the subagent whenever it's available.

## What the Reviewer Should Not Do

Scope the reviewer tightly. It should not:

- **Suggest alternative architectures.** The design is decided. The review is
  about whether the implementation is correct, not whether a different approach
  would have been better.
- **Evaluate style preferences.** The authoring agent followed the codebase
  conventions; the reviewer shouldn't second-guess them.
- **Propose new features or scope additions.** The contract is the contract.
  Gold-plating is not a review finding.

A reviewer prompted to find gaps will usually report some, even when the work is
sound. Chasing every finding leads to over-engineering. Reconcile, don't obey.

## Anti-Rationalizations

| Rationalization | Reality |
|---|---|
| "I'm confident this is correct" | Confidence is highest right after authoring, which is exactly when blind spots are worst. |
| "The tests pass, so it's fine" | Tests verify the behaviors you thought to test. Review catches the ones you didn't. |
| "This change is small enough to skip review" | Small changes cause large outages. The review cost for a small change is also small. |
| "Review will just slow things down" | Catching a bug before commit is faster than debugging it after. |
| "I already considered the edge cases" | You considered them in the same context that wrote the code. An independent reviewer checks whether you missed any. |

## Key Principles

1. The reviewer sees only the artifact and the contract, never the authoring rationale
2. Fresh context is the mechanism — "review your own work" in the same session doesn't work
3. Classify findings by severity; fix Critical and Issue, don't churn on Nits
4. One cycle by default, two max, then escalate to the user
5. The review checks correctness against the contract, not style or design alternatives

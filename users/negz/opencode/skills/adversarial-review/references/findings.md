# Calibrating Findings

A reviewer asked to find problems will find some. The hard part is deciding
which ones are real, and a checklist won't tell you. These are real review
findings and what Nic actually did with them, so use them to calibrate before
you act on a report. He declines roughly as often as he accepts, for consistent
reasons.

## Declined: a guard the API layer already handles

A bot review asked for a runtime check on a field that was about to get schema
validation.

> "Wait isn't this guard the same thing as what #28 tracks? I don't think we
> should do it in code and also at the API level."

Enforce an invariant in one place. A finding that adds a second enforcement
point leaves two things to keep in sync, and one of them will drift.

## Declined: defensive documentation nobody else writes

A reviewer flagged that a library function took a caller-built map without
documenting whether it took ownership.

> "No, I don't think even that is warranted. This comment strikes me as an
> overzealous LLM (I think this whole review is a low effort LLM job). There's
> tons of places in Crossplane where the caller builds a datastructure to pass
> to a library module without the library documenting or defending against
> this."

Two lessons. Ordinary language semantics don't need documenting, and a finding's
source doesn't make it right. Bot reviews and junior reviews are inputs to
judge, not work queues.

## Declined: an extraction that missed the point of the comment

A reviewer asked for a value to be computed once rather than twice. The agent
extracted a shared predicate that was still evaluated at both call sites, then
defended it.

> "He's not asking for a helper called twice right? He's asking for it to be
> computed once."

and later, on the same thread:

> "I declined the nit."

Read what a finding actually asks for. Deduplicating an expression is not the
same as computing a value once, and satisfying a review comment badly is worse
than declining it.

## Accepted, with the noise stripped

A ten-item bot review on a composition function:

> "Let's do everything but 6 and 7. Do them in distinct commits - I prefer that
> approach over one big 'fix review feedback' commit, since it tells a better
> story and is more granularly revertable if needed."

Note both halves. Eight of ten were worth doing, so the review had value. The
fixes still went in as separate commits rather than one batch.

## What to take from this

- **Report a finding with the evidence, not just the concern.** "This could be
  nil" is worth less than "this is nil when the XR omits `spec.workers`, which
  the schema allows".
- **Say when a finding rests on precedent alone.** "The rest of the repo does X"
  is weak evidence, because nobody may have reviewed the rest of the repo.
- **A finding that adds code needs a higher bar than one that removes it.**
  Guards, wrappers and defensive documentation are the usual over-corrections.
- **Don't act on every finding.** Reconcile, don't obey. Acting on all of them
  is the same failure as ignoring all of them, and it's how a change acquires
  machinery nobody asked for.

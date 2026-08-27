# Validating a Change

The designs below come with the briefs to run them, ordered by value per unit of
effort, so start at the top.

Whatever you run, don't tell a subagent which rule is under test. An agent told
what you're measuring will satisfy the measurement.

## Blind Preference Test

The cheapest and most decisive. Run this one always.

Take real flagged phrases from real artifacts, propose a rewrite for each, and
ask Nic which he prefers. Present them neutrally, without marking which side you
favour, because your marking is what the test exists to check.

Format each as:

```
**N. `RuleOrPrinciple`** — file:line
> the original text

your rewrite
```

Cover every rule or principle that fired, including the ones you believe are
noise. Pre-filtering by your own assessment hides the cases where you're wrong,
which are the cases worth finding. In the writing calibration, 14 of 16 went to
the rewrite, and the two exceptions were ties. That reversed a conclusion two
earlier tests had missed.

Where you can't construct a rewrite, say so rather than inventing a
weak one. That's a finding about the rule.

## A/B Against the Old Guidance

Same task, old version against new, fresh subagents that never saw the working
session.

Design points that matter:

- **Identical input.** Verify with `md5sum` and say so. Adapting the prompt per
  arm invalidates the comparison.
- **Realistic task.** Use a task from the corpus, ideally one where Nic ended up
  rewriting the output himself, because you then have ground truth.
- **Objective metrics where they exist.** Word count and linter alert count are
  countable. Report them next to the subjective read.
- **Withhold the rule under test.** Brief the subagent as though this were real
  work.

Retrieve the old guidance from git rather than from memory:

```bash
git show HEAD:path/to/SKILL.md > /tmp/old-SKILL.md
```

Then point each arm at its own copy and its own output directory.

## Trap Replay

The only design that proves a judgment rule works, since judgment resists
counting.

Find a specific historical failure in the corpus, including what Nic objected to
and what the agent did next. Reproduce it by feeding the same draft and then the same
objection, and see whether the new guidance changes the second response.

Give both arms byte-identical input, including the objection, quoted verbatim
from the transcript. Adapting the objection to each arm's draft is tempting and
ruins the comparison, so prefer a shared starting draft.

Score the outcome by whether the failure recurs, not by whether the output reads
better. In the writing calibration the control renamed its headings after the
reviewer's objection and grew 37%, while the new arm dropped the disputed claim
and shrank 16%. That difference is the rule working.

## Reviewing Prose or a Commit Message

For checking a specific artifact rather than a guidance change, brief a
fresh-context subagent with the artifact and nothing else. Constrain it to
subtractive findings:

```
Answer only these two questions:

1. Which claims in this text does the source material not support?
2. What does this text say that the source material already shows?

Recommend cuts only. Do not suggest anything to add, and do not say what's
missing. If you think something is missing, keep it to yourself. Text that grows
in review is a failed review.
```

The asymmetry is the point. A reviewer invited to say what's missing always finds
something, and the artifact grows every round, which is usually the problem you
started with. This brief caught an invented causal link in a commit message that
would otherwise have reached the permanent record.

## Reporting Results

Lead with the tally, then the reversals. Say plainly where the test contradicted
your earlier position, and name the specific claim it overturned. A validation
report that confirms everything you already believed is a sign the test was
too weak or the sample was pre-filtered.

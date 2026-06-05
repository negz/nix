---
name: negz-review
description: >-
  Review code and docs the way negz reviews them - naming, Go idiom, Kubernetes
  API conventions, simplicity (YAGNI), consistency with existing patterns,
  testing style, comments, and compatibility. Use when reviewing a PR or diff,
  when asked for a review or sanity check, or before committing non-trivial
  changes to a Crossplane (crossplane or crossplane-contrib) Go or docs project.
  Complements adversarial-review: that skill checks correctness, this one checks
  whether the change is the kind of code negz would approve.
---

# negz Review

This skill encodes the review judgment negz has applied across ~2,500 PRs in the
crossplane and crossplane-contrib orgs over ~7 years. It turns that judgment into
a checklist plus a feedback style, so an agent can catch most of what negz would
catch on a first pass and phrase it the way he would.

## When to Use This (vs adversarial-review)

Use **adversarial-review** to answer "is this correct?" — bugs, contract
violations, edge cases, error paths. It deliberately ignores style and design.

Use **this skill** to answer "is this the kind of code negz would approve?" —
naming, idiom, conventions, simplicity, consistency, docs, compatibility. The two
are complementary; for a substantial change, run adversarial-review for
correctness and this for craft. This skill is the right one when the user asks
for "a review," names negz, or is working in a Crossplane repo.

Scope: strongest on Go and Markdown in Crossplane repos. The principles transfer,
but the cited conventions (crossplane-runtime errors and logging, KRM) are
Crossplane-specific.

## How to Review

Work through the diff once per concern area below, in priority order. Naming,
simplicity, and consistency catch the most — start there. For each finding,
follow the **Feedback Style** rules: most findings are framed as a question or a
proposed alternative, taste is labelled `Nit:`, and you cite a source rather than
asserting a preference.

Read [references/conventions.md](references/conventions.md) for the verbatim
rules, canonical links, and example phrasings. Load it whenever you need the
exact convention or the source to cite.

### 1. Naming (highest yield)

Names are design. For every new identifier — type, field, func, var, flag,
package, test name — ask:

- **Is it precise?** Does the name say exactly what the thing is and does? Vague
  names (`Config`, `data`, `process`) usually want to be more specific.
- **Could it be confused with an adjacent concept?** e.g. a template's name field
  should be `templateName`, not `name`, so it isn't mistaken for `metadata.name`.
- **Is it idiomatic Go?** No underscores in func/test names (`TestWorkspaceApply`,
  not `TestWorkspace_Apply`). No camelCase in package names. Booleans read as
  predicates (`ready[dep]`, `if satisfied[dep]`).
- **Does the convention match intent?** "verbs that allow X" not "verbs for X";
  `EnableWebhooks` not `EnableWebhook` when there's more than one.
- **Does the JSON tag match the field**, and follow camelCase?

### 2. Simplicity / YAGNI

Default to less code. Flag:

- Redundant checks (a guard the caller already guarantees; `errors.Wrap`'s own
  nil check making an `if err != nil` redundant; a type assertion plus a
  separate nil check that overlap).
- Dead or no-op branches — "Do we need this branch? Removing it gives a no-op."
- Premature abstraction and unused flexibility — "Do we need this now?"
- Bespoke reimplementations of solved problems — "Is there prior art? What does
  `kubectl diff` / the stdlib / an existing helper do?"
- Detail at the wrong level (implementation detail leaking into user docs or a
  help string).
- Deep nesting that an early return / guard clause would flatten — "You could
  return early here to avoid indenting the bulk of this function." Invert the
  condition and handle the error/edge case first.
- Multi-line code that collapses to a readable one-liner — e.g. an `if err != nil`
  block around a single `errors.Wrap` return (see Go idiom below). negz reaches
  for "sweet, sweet brevity" often; offer the shorter form as a `suggestion`.

The question to ask, literally, is **"Do we need this?"** If removing it loses
nothing, it should go.

### 3. Consistency with existing patterns

Crossplane code values uniformity. Before accepting a new pattern, check how the
rest of the repo does the same thing, and prefer that:

- Tests: table-driven, with a `reason string` per case.
- Comparison in tests: `cmp.Diff(want, got)` (with `cmpopts.EquateErrors()` and
  `cmpopts.EquateEmpty()`), **not** `reflect.DeepEqual` and **not** `cmp.Equal`
  for assertions — the idiom is `cmp.Diff(...) != ""`.
- Expected errors: `err: cmpopts.AnyError` to assert *an* error occurred, rather
  than reconstructing the concrete wrapped error in the want. Flag a test that
  rebuilds `errors.Wrap(errBoom, "...")` in its want unless the exact error value
  is genuinely part of the contract.
- Errors: in a Crossplane project, the crossplane-runtime errors package
  (`github.com/crossplane/crossplane-runtime/v2/pkg/errors`), `errors.Wrap`/
  `Wrapf`, not `fmt.Errorf`. Outside a Crossplane project, stdlib `errors` /
  `fmt.Errorf("...: %w", err)` is fine — don't reach for `github.com/pkg/errors`.
- Logging: the crossplane-runtime `logging` package, structured, with
  `"error", err` — there is intentionally no `Error` method.
- Reconcilers: follow the established condition + event + debug-log + requeue
  pattern; match the "latest and greatest" reconciler in the repo.
- Reuse the same example values, flag names, and phrasings used elsewhere.
- Reuse existing constants, helpers, and types rather than hard-coding or
  reimplementing — "Does the upstream package / our codebase already have a
  constant we could reuse for this?" Magic strings and numbers that duplicate an
  existing definition are a flag.
- Parallel structure: if a resource models one related thing a certain way, the
  sibling thing usually should too. When a new API type references e.g. a subnet
  but not the security group beside it, ask "we model SGs elsewhere — could this
  have reference and selector variants too?" Look for the asymmetry.

If the author diverged from a repo convention, ask them to match it — or to add a
comment explaining why they didn't.

### 4. Go idiom

- `errors.Wrap(err, ...)` returns `nil` when `err` is `nil` — so a preceding
  `if err != nil { return errors.Wrap(... ) }` collapses to a single return.
- `Wrapf` only when the message contains formatting; otherwise `Wrap`.
- Accept interfaces, return structs. Don't return interfaces — it forces readers
  to chase the real implementation.
- Prefer the smallest interface a function needs (`Cluster`, not the whole
  `Manager`; `client.Client` narrowed to what's used).
- Panic, don't return an error, for programmer error / a fundamentally broken
  binary (e.g. `AddToScheme` failing at startup, an impossible type assertion).
- Don't leak another package's types or options through your public API; wrap
  them in your own abstraction so you control the surface (Hyrum's Law).

### 5. Kubernetes / KRM API conventions

Treat the Kubernetes API conventions as the source of truth (cite the link):

- Optional vs required: optional fields are pointers with `+optional` and
  `omitempty`; required fields are not.
- `spec` is desired state (user-writable); `status` is observed state
  (read-only from the user's perspective — strip "READ-ONLY" notes from status
  field docs, they confuse users).
- Use status conditions and the standard condition vocabulary.
- Terminology: a thing of `kind: Foo` is a *custom resource*, not a *CRD*. A CRD
  is the *definition*. Don't conflate them in code or docs.
- Adding a new optional field is not a breaking change; changing types, casing,
  return signatures, or metric names is.

### 6. Comments and documentation

- Godoc and comments explain **why**, not **what**. Ask for a comment when intent
  is non-obvious (why a linter is disabled, why a no-op exists, a documented API
  limitation). Push back on comments that merely restate what the code plainly
  says.
- Flag comments that **narrate the change rather than describe the current
  state** — "use Y, not X", "switched from X to Y". The reader sees Y and rarely
  cares about X; that history belongs in the commit message. The exception is when
  the old approach is a live temptation (a reader would wonder "why not the obvious
  way?" or be tempted to refactor back to something that was bad for a non-obvious
  reason) — then naming X is part of explaining the *current* code's rationale.
- Exported identifiers need Godoc; readers of pkg.go.dev can't see private types,
  so don't explain a public symbol by referencing a private one.
- Markdown: wrap at 80 chars (it makes raw text readable and lets reviewers
  comment on specific lines); don't mix wrapped and unwrapped within a file.
- Docs should hit the right level of detail for their audience — link to the spec
  for internals rather than inlining them.

### 7. Tests

- New code paths need tests — especially error and requeue paths. Call out
  untested branches you introduce.
- Table-driven, with `reason` strings; use `cmp.Diff`.
- Don't unit-test trivial constructors.
- Put test-only helpers/registrations in the test file, not production code.

### 8. Compatibility

- Is this a breaking change for users, API consumers, provider implementations,
  or metrics dashboards? Say so explicitly and weigh it.
- Can the change be made non-breaking (keep old casing, add an alias, mark
  deprecated rather than remove, gate behind alpha)? Prefer that.
- New public packages create a maintenance obligation — be wary of exposing
  internals "since there's no stability guarantee" (Hyrum's Law).

## Feedback Style

Phrase findings the way negz does. This is not cosmetic — the framing is what
makes feedback land as collaborative rather than dictatorial.

- **Ask, don't decree, when the author may have context you lack.** "Do we need
  this branch?" / "Should this be `X`?" / "Is there a reason we do Y rather than
  Z?" Roughly a fifth of his comments are questions.
- **Always offer a concrete alternative.** Not "this is wrong" but "rather than X,
  how about Y?" When the fix is small and mechanical, write a GitHub
  ` ```suggestion ` block with the exact replacement.
- **Label taste as `Nit:`** (or "Nitpick:") and make clear it's non-blocking, so
  the author can tell must-fix from preference.
- **Cite the source.** Link the api-conventions doc, Go Code Review Comments,
  pkg.go.dev, the runtime package — let the authority carry the weight instead of
  "I prefer." See references/conventions.md for the canonical links.
- **Hold opinions loosely and say so.** "I don't feel strongly, but…" /
  "Either way is fine" when it genuinely is.
- **Be terse.** Most findings are one sentence. Don't pad.
- **Acknowledge good work.** "Good catch," "Nice," "LGTM once X is fixed."

### Severity, for the summary

Group findings so the author sees what blocks merge:

- **Blocking** — convention violations the project won't accept, correctness
  risks, breaking changes that need handling.
- **Nit** — taste and minor idiom; fix if cheap, skip if not.
- **Question / FYI** — genuine questions and observations.

## What This Skill Will Not Catch

Be honest about the ceiling. This is a strong first-pass filter, not a
replacement for human design review. It will not reliably catch:

- Whether the **overall design** is right (should this be a separate subcommand?
  does this coupling belong? is this the right framework?). negz's hardest
  reviews enumerate a system-level rationale that needs full context and taste.
- Domain-specific correctness that requires knowing how a provider's external API
  behaves, or how a feature interacts with the rest of Crossplane.

When the change has real design weight, surface that to the user rather than
pretending the checklist settled it. The strongest move negz makes — writing out
his model of what each new type is for and checking each is necessary — is a
prompt to *think*, not a rule to apply.

## Key Principles

1. Naming, simplicity, and consistency catch the most — review those first.
2. Default to less code: "Do we need this?" is the most-used question for a reason.
3. Anchor every convention to the repo's existing pattern or an external source — cite it.
4. Frame findings as questions and concrete alternatives; write `suggestion` blocks for small fixes.
5. Separate blocking issues from `Nit:`s so the author knows what matters.
6. Be terse, hold opinions loosely, and acknowledge good work.
7. Know the ceiling: this catches craft, not system design — escalate real design questions.

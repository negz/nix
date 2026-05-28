---
name: no-shortcuts
description: >-
  Resist the temptation to defer hard problems in greenfield work. Use when
  starting a new project, building a new feature or subsystem, prototyping, or
  doing any work where feasibility is uncertain. Also use when considering
  deferring something because it's difficult, complex, or risky — phrases like
  "for now we can just", "we can add it later", or "to keep v0.1 simple".
---

# No Shortcuts

## When to Use This Skill

Use this skill when:

- Starting a new project
- Building a new feature or subsystem in an existing project
- Prototyping, or building an MVP or v0.1
- Doing any work where the goal is to validate feasibility or build confidence
  in an approach

Do not use it for bug fixes, incremental changes to established features, or
work in a mature codebase where the patterns are already settled. There, the
risk has already been retired — the job is to fit in, not to derisk.

## The Point of Greenfield Work

Greenfield work exists to build confidence: confidence that an idea is worth
pursuing, and that it can be done well. That's the goal, not shipping a feature.

This reframes what "minimal" means. The hard parts — the API shape, whether the
core idea is even feasible, the load-bearing architectural decisions — are
exactly the parts that need to be tackled first. They carry the risk. A v0.1
that only proves you can do the easy parts has proved nothing, because the easy
parts were never in doubt.

The instinct to defer hard things is backwards. Hard things are deferred because
they're hard, but their difficulty is correlated with their risk, and risk is
the thing greenfield work is supposed to retire.

## Two Kinds of Simplification

Not all simplification is a shortcut. The distinction is everything.

**Simplify the approach (good).** Use a naive algorithm, an in-memory store
instead of a database, a hardcoded value instead of configuration, skip
optimization. These simplify *how* you build without hiding whether the idea
works. The risk they remove was never real risk.

**Simplify away the hard problem (bad).** Skip the API design, leave out the
part that needs a novel approach, defer the integration that determines
feasibility, stub out the thing the whole project exists to validate. These
simplify *what* you build, and they leave the real risk untouched — just hidden
until later, when discovering it is most expensive.

The test: does the simplification remove work, or does it remove a question you
were supposed to answer? Removing work is fine. Removing the question defeats
the purpose.

### Examples

- **Good:** Use an in-memory map instead of a database. The data access pattern
  is a solved problem; swapping storage later is mechanical.
- **Bad:** Skip the reconciliation logic because "we can add it later."
  Reconciliation is what determines whether the controller is feasible. Without
  it you've built a shell, not a prototype.
- **Good:** Hardcode a single provider instead of supporting three. You're
  validating the abstraction, not the provider count.
- **Bad:** Skip the provider abstraction entirely because "we only need one for
  now." If the abstraction doesn't hold up, adding it later means rewriting
  everything built on top of it.

## Anti-Rationalizations

These are the excuses for deferring hard things. Each one sounds reasonable.
Each one is usually wrong in greenfield work.

| Rationalization | Reality |
|---|---|
| "For v0.1 we can just use a simple X" | If X determines whether this project works, simplifying it away validates nothing. |
| "We can add Y later" | If Y affects API shape, data model, or architecture, adding it later means rewriting. Discover that now. |
| "Let's skip the hard part for now" | The hard part is why this project exists. Easy things don't need greenfield validation. |
| "We don't need Z yet" | If Z determines feasibility, it's the first thing to build, not the last. |
| "Keep it simple" | Simple approach: yes. Avoiding the core challenge: no. |
| "This is just a prototype" | Prototypes exist to answer hard questions. "Can we do the easy parts?" is not one. |
| "We can refactor when we know more" | You learn the most by attempting the hard thing. Deferring it means learning less. |
| "It's too risky to attempt that now" | Risk is the reason to attempt it now. Late discovery of infeasibility costs far more. |

## What to Tackle First

When starting greenfield work, prioritize in roughly this order:

1. **Feasibility risks.** Things that might not be possible at all. If these
   fail, the project doesn't make sense — find out before building around them.
2. **API shape and data model.** The contracts other code will depend on.
   Getting these wrong means rewriting everything downstream.
3. **Load-bearing architectural decisions.** Choices that are expensive to
   reverse — sync vs. async, push vs. pull, embedded vs. external.
4. **Integration points.** Interfaces with external systems, where assumptions
   need to be validated against reality rather than imagined.
5. **Features.** Actual functionality, built on the foundation validated above.

The ordering is by risk, not by ease. The whole point is to confront the
uncertain things while changing course is still cheap.

## Red Flags

When you catch yourself thinking or writing any of these, stop and ask whether
you're deferring real risk:

- "For now we can just..."
- "We can always add ... later"
- "To keep things simple, let's skip..."
- "This is good enough for v0.1"
- "We don't need to worry about ... yet"
- "The hard part is ..., but we can defer that"

The phrase isn't always wrong — sometimes the deferred thing really is
peripheral. But it's a reliable signal to check: is this an easy thing being
deferred for convenience, or a hard thing being deferred because it's hard? The
latter is the one to pull forward.

## Key Principles

1. Greenfield work exists to build confidence, not to ship features
2. The hard problems are the ones most worth tackling early
3. Simplify the approach, never the problem
4. If it affects API shape, data model, or architecture, do it now
5. Deferring risk doesn't reduce it — it hides it until discovery is costliest
6. A v0.1 that only proves the easy parts are easy proved nothing

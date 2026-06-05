---
name: before-writing-code
description: >-
  Core engineering principles to apply before beginning implementation in any
  language. Read at the start of a coding session, before writing the first new
  code, refactor, or change to existing code. Establishes how to approach a
  codebase, design for change, and decide what to verify.
---

# Before Writing Code

These principles hold in any language. Read them before starting implementation
in a session — before the first new code, refactor, or change to existing code.
They're about how to approach the work, not the syntax of any one language.

## Read Before You Write

Read the surrounding code before you add to it. Match its conventions — naming,
structure, error handling, testing style. A codebase that does one thing one way
should keep doing it that way, even when your personal preference differs.
Consistency within a codebase beats any individual preference.

This applies to the mechanics, not the goals. Good engineering — clear names,
handled errors, testable structure — applies everywhere. But the specific way a
codebase achieves those goals is a settled choice you should follow, not
relitigate.

## Design for Change

Make the choice now that keeps future options open. Reversing a decision after
code depends on it is expensive; choosing a shape that evolves additively is
cheap. When a field might plausibly need more than one value, or a flag might
become three options, or a function might grow a second caller, lean toward the
shape that absorbs that change without a rewrite.

The cost of leaving room is usually a little extra structure today. The cost of
not leaving room is a breaking change later. The trade is almost always worth it.

## Don't Defer the Hard Things

In new work, the hard parts are usually the ones that carry the risk worth
retiring early — whether an idea is feasible, what the right interface is,
whether the approach holds up. Deferring them because they're hard doesn't reduce
the risk; it hides it until the cost of discovery is highest.

Simplify the approach freely — a naive algorithm, an in-memory store, a hardcoded
value. But don't simplify away the problem itself. Removing work is fine; removing
the question you were supposed to answer is not.

## Verify, Don't Assume

Confidence is not evidence. Before using an unfamiliar API, read its actual
documentation rather than recalling it from memory — training data is full of
outdated signatures and plausible-but-wrong patterns. Before declaring a change
correct, check it: run the tests, run the build, read the diff with fresh eyes.

The pattern in every case is the same: replace "I'm sure this is right" with
something that proves it.

## Comment the Why, Not the What

The code already says what it does. A comment that restates it is noise. A
comment earns its place by explaining what the code *can't* say: why a
non-obvious decision was made, and especially what external constraint forced it
— an upstream library's behaviour, a protocol quirk, an API that rejects the
obvious approach, a bug you're working around. That context is invisible in the
code and expensive to rediscover, so capture it at the point it matters.

```go
// SetConditions sets conditions to nil if passed no arguments. SSA interprets
// this as null and rejects it, so we only set them when there's something to set.
if len(cs) > 0 {
    xr.SetConditions(cs...)
}
```

The test: if a reader could derive the comment from the line below it, delete the
comment. If they'd need to go read another package's source, a changelog, or an
issue to understand why the code is shaped this way, write it down.

### Describe the State, Not the Change

When you change code from approach X to approach Y, do not leave a comment (or
commit-shaped narration in the code) that says "do Y, not X". The reader sees the
current code — Y — and almost never cares how it used to be. They want to
understand why the code is the way it is *now*, on its own terms. "Use a map here,
not a slice" or "Switched to SSA instead of patching" is noise: it documents your
edit, which belongs in the commit message, not the source.

```go
// Bad — narrates the change.
// Use errors.Is here instead of == so wrapped errors still match.

// Good — describes the current state and its reason.
// The client wraps this error, so compare with errors.Is rather than ==.
```

The change is only worth mentioning in the rare case where the *old* approach is
a live temptation:

- A reader would reasonably wonder "why not the obvious way?" — name the
  obvious-but-wrong alternative and why it doesn't work.
- A reader would reasonably be tempted to refactor back to the old approach,
  which was bad for a non-obvious reason — warn them off it.

Both of these are really just "comment the why": the old approach is part of the
*current* code's rationale, not a history lesson. If it isn't, leave it out.

Mark deferred work and surprising decisions with an attributed marker so the next
reader knows who to ask and that it was deliberate — `TODO(user):` for work left
undone, `NOTE(user):` for a decision that looks wrong until you know the reason.
Phrase a TODO as the open question it is ("Use server-side apply instead?"), not
a vague "fix this later".

## Structure for Testability

Testability is a design property, decided when you structure the code, not
something you bolt on afterward. Code that's hard to test is usually telling you
the design is wrong — dependencies that should be injected are hardwired, side
effects are tangled with logic, a function does too much.

Build the seams in as you write. If you find yourself unable to test something
without standing up real infrastructure, treat that as a signal to restructure,
not a reason to skip the test.

## Key Principles

1. Read the surrounding code first — consistency beats personal preference
2. Design for change — keep future options open, reversing decisions is costly
3. Don't defer the hard things — simplify the approach, never the problem
4. Verify, don't assume — evidence over confidence
5. Comment the why, not the what — capture the constraint the code can't show
6. Structure for testability — seams are a design decision, not an afterthought

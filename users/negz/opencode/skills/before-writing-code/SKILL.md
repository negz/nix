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
5. Structure for testability — seams are a design decision, not an afterthought

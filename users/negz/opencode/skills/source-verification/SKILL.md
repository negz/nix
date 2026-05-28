---
name: source-verification
description: >-
  Verify APIs and library usage against actual documentation before writing
  code. Use when introducing a new dependency, using an API not already
  established in the codebase, upgrading a library version, or when unsure
  whether an API exists or works as expected. Also use when the user mentions
  checking docs or verifying an API, or when you notice yourself writing code
  for an unfamiliar library from memory.
---

# Source Verification

## When to Use This Skill

Use this skill when:

- Introducing a new dependency
- Using an API from an existing dependency that the codebase doesn't already use
- Upgrading a library version
- Unsure whether an API exists or behaves the way you expect
- You notice yourself writing code for an unfamiliar library from memory

Do not use it for APIs already well-established in the codebase — if the
codebase already calls a method with certain arguments, that usage is verified
by the existing code. Don't use it for standard library functions you're
genuinely confident about. But if that confidence isn't backed by evidence,
check anyway.

## Why This Matters

Training data contains outdated API signatures, deprecated patterns, and
plausible-but-wrong usage. The agent is confidently fluent in APIs it has never
actually read the docs for. The result is code that looks correct, compiles in
the agent's imagination, and fails at build time — or worse, at runtime, with
subtle behavioral differences from what was intended.

The fix is simple: read the actual documentation for the actual version before
writing the code. This is what a careful human developer does. The agent should
do it too.

## The Process

### Check the version

Before anything else, find the exact version the project uses. Check `go.mod`,
`package.json`, `pyproject.toml`, `flake.nix`, `Cargo.toml`, or whatever
dependency file the project uses. The API for v2.3 may differ from v3.1; the
version determines which docs are correct.

### Read the docs

Use the WebFetch tool, or read bundled documentation. Prefer sources in this
order:

1. Official documentation for the specific version
2. Official blog posts or changelogs for the specific version
3. The source code of the dependency itself — godoc, type signatures, comments
4. Web standards or RFCs, for protocol-level behavior

Do not rely on: training data, Stack Overflow, third-party tutorials, blog
posts, AI-generated documentation (it's circular — model output describing model
output), or "I'm pretty sure it works like this."

### Cite or flag

When you've verified the API, proceed normally. When you can't find
documentation, or the docs are ambiguous, say so explicitly. Mark it with
`UNVERIFIED` in a code comment:

```go
// UNVERIFIED: Could not find official documentation for this behavior.
// Based on reading the source of v2.3.1. May need validation.
```

A disclaimer buried in prose doesn't help. Hedging ("I think this might work")
is the worst option — it's neither verified nor clearly flagged. Either verify
and cite, or clearly mark it as unverified so the user knows where to look.

## What Counts as "Unfamiliar"

The line isn't whether you've seen the API in training data. It's whether the
*codebase* has established usage.

If the project already has twenty calls to a method with a certain signature,
that pattern is validated by the existing code — follow it. If you're about to
use a different method from the same library for the first time in this codebase,
that's unfamiliar, even though the library itself is well-established.

Rules of thumb:

- New dependency → always verify
- New API from an existing dependency → verify
- API already used in the codebase → don't re-verify, follow the existing usage
- Version upgrade → verify for breaking changes

When established codebase usage conflicts with the current docs — common after a
version bump — don't silently pick one. Surface both to the user with sources:
the existing pattern and what the docs now say. The codebase may be outdated, or
the docs may not apply to the pinned version. Let the user decide.

## Anti-Rationalizations

| Rationalization | Reality |
|---|---|
| "I'm confident this API works like this" | Confidence is not evidence. Training data contains deprecated signatures and plausible-but-wrong patterns. Check the docs. |
| "I've seen this pattern in many projects" | Popularity doesn't mean correctness, and the version may differ. Read the docs for *this* version. |
| "It compiled, so the API is right" | Compiling means the types match. It doesn't mean the behavior is what you expect. Semantic misuse is the dangerous kind. |
| "The docs are hard to find, I'll go with what I know" | If the docs are hard to find, flag it as UNVERIFIED. Don't quietly guess. |
| "Checking docs is slow, the user wants speed" | Debugging a hallucinated API is slower. A 30-second doc check prevents a 30-minute debugging session. |

## Key Principles

1. Check the version first — API behavior is version-specific
2. Read official docs, not training-data recall
3. Cite what you verified; flag what you couldn't as UNVERIFIED
4. "Already used in this codebase" is valid verification — don't re-check established patterns
5. Semantic misuse (right types, wrong behavior) is more dangerous than wrong types, which the compiler catches

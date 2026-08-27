# The Mechanisms

What each remedy costs, where it lives, and what it suits. Prefer whichever one
furthest down the determinism scale can carry the lesson, because an agent can
skip an instruction and can't skip a failing check.

## Linter Rules

**Suits** anything a pattern can match in text. Banned phrasings, punctuation
habits, overused vocabulary, passive voice.

Nic runs Vale over Markdown, configured globally at
`~/.config/vale/.vale.ini`, which Nix generates from
`users/negz/configuration.nix`. Nix pins both rulesets there as `fetchzip`
derivations and joins them with `symlinkJoin`, since Vale accepts one
`StylesPath`.

Adding a rule to an existing ruleset means either upstreaming it or writing a
local style directory. Enabling or retuning an existing rule is a config line:

```ini
Google.Passive = error          # enable a rule from a style not in BasedOnStyles
ai-tells.FormalRegister = warning   # downgrade one that misfires
Google.Acronyms = NO            # disable
```

Constraints worth knowing before proposing a rule change:

- Severity is per rule. `Style.* = warning` is silently ignored, and no per-style
  setting exists. A blanket change means one line per rule, which `builtins.readDir`
  can generate.
- Path scoping doesn't work reliably. Section globs like `[design/*.md]` had no
  effect in testing, and one form applied globally while appearing scoped.
- opencode reports only LSP severity 1 to an agent, and caps the report at 20 per
  edit. A rule at `warning` or `suggestion` reaches Nic's editor and never
  reaches an agent, so adopting a rule usually means raising it to `error`.

**Cost.** Low to add, and it applies without anyone remembering it. The risk is
false positives, which train an agent to ignore alerts. Measure the rate on a
real document before adopting.

## Other Deterministic Checks

**Suits** anything detectable by running something rather than by matching text.
Type errors, test failures, formatting, schema validation.

In this configuration that means `nix flake check`, which already gathers
linters, formatters, type checkers, and unit tests. Adding a check there makes it
run in CI and locally with no instruction attached.

**Cost.** Higher to write than a linter rule, and stronger, since it can encode
semantics rather than shape.

## Skills

**Suits** judgment that resists mechanisation. Whether a section argues with a
reviewer, whether an agent invented a rationale, whether a document is proportionate.

Skills live in `users/negz/opencode/skills/`, one directory each, generated into
`~/.config/opencode/skills/` by Nix with `recursive = true`. Stage new files in
git before the flake can see them, or subdirectories silently fail to
materialise.

Hand the writing to **skill-creator**. Keep the delta first, keep the body under
500 lines, and push reference material into `references/`.

**Cost.** Loads only when the description triggers, so a correct skill that never
fires is worthless. Triggering is a separate problem from content.

## AGENTS.md and Global Instructions

**Suits** rules that hold for every task in a project regardless of context, where
waiting for a skill to trigger is too late. Build commands, house conventions, the
voice to write in.

`AGENTS.md` sits at a repo root and loads for every session in that repo.

**Cost.** Always in context, so it competes for attention with everything else.
Reserve it for rules with no natural trigger, and keep it short.

## opencode Configuration

**Suits** friction that knowledge can't fix. A missing language server, a tool
that isn't on PATH, a permission prompt that interrupts, a linter with no config
outside the editor.

Configured in `users/negz/configuration.nix` under `xdg.configFile` as
`opencode/opencode.json`, covering `lsp`, `permission`, and related settings.

**Cost.** Low, and frequently the real fix. When an agent repeatedly fails at
something mechanical, check whether it has the tool before writing guidance about
the technique.

## Subagents with Fresh Context

**Suits** anything the acting agent structurally cannot see. Its own reactive
framing, a rationale it supplied from memory, whether its prose reads as
machine-written.

Encode this as a brief in a skill's `references/`, so the skill instructs the
dispatch and the reference holds the prompt. See
[validation.md](validation.md) for the shape.

**Cost.** A round trip per invocation. Worth it where the failure is invisible
from the inside, and wasteful for anything a check can catch.

## Scripts and Plugins

**Suits** a deterministic sequence repeated often enough that reinventing it wastes
time or invites variation.

A script belongs in a skill's `scripts/`, where an agent can run it without
loading it into context. A plugin belongs in opencode's plugin configuration, and
suits behaviour that should apply without a skill triggering.

**Cost.** Highest to build and maintain. Reach for it when the same multi-step
recipe appears in several sessions.

## Pairing Mechanisms

One finding often wants two. Vale should hold the rule about em dashes, since a
regex applies mechanically. The skill should explain why it matters, so an agent
meeting the alert understands what it's for rather than working around it.

Where you split a lesson this way, make the skill reference the check by name.
Guidance that silently duplicates a linter drifts from it.

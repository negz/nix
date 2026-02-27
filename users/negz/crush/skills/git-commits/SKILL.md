---
name: git-commits
description: Write git commits in Nic Cope's style. Use when creating commits, staging changes for commit, or when the user asks to commit. Includes Signed-off-by requirements and problem-first messaging.
---

# Git Commit Style Guide

## IMPORTANT: Require Confirmation

**Never run `git commit` without explicit user approval.** Always:
1. Draft the commit message
2. Show it to the user
3. Wait for confirmation or requested changes
4. Only then create the commit

## Required Format
- **Always** include: `Signed-off-by: Nic Cope <nicc@rk0n.org>`
- Subject line: 50-80 characters, imperative mood
- Body: Wrap at 80 characters, explain the "why"

## Subject Line Patterns
- Start with imperative verbs: "Fix", "Add", "Update", "Implement", "Use", "Support"
- Be specific and technical: "Fix CRD-to-MRD converter to preserve provider configuration CRDs"
- Include scope when helpful: "Use WIRE_JSON level buf breaking change detection"
- Avoid vague terms: Not "Update code" but "Fix composed resource names containing invalid characters"

## Body Content
- **Problem-first**: Explain what was wrong or missing
- **Solution flow**: Use natural language like "This commit replaces..." or "This change updates..." not bare imperatives
- **Technical details**: Include implementation specifics
- **Behavior changes**: Show before/after examples when relevant
- **Context**: Reference related issues, design decisions, trade-offs
- **No bragging**: Don't say things are "elegant", "robust", or "powerful"
- **No table stakes**: Don't mention tests, code formatting, linting fixes, or other expected practices. Focus on what the code does, not on proving you followed development standards.

## Example

```
Fix XRD controller restart to detect all spec changes

When XRD spec fields change, the XR controller doesn't always restart
automatically. Users must manually restart the Crossplane deployment for
some changes to take effect, as reported in issue #6736.

The existing restart logic only detected referenceable version changes.
This missed other spec changes like connection details modifications.

This commit replaces the referenceable version based detection with
generation-based controller restart detection using the existing
condition system. The ControllerNeedsRestart() helper checks if the
WatchingComposite condition's observedGeneration differs from the
current metadata.generation.

Fixes #6736.

Signed-off-by: Nic Cope <nicc@rk0n.org>
```

## Key Principles

1. Be technical, not promotional
2. Explain problems before solutions
3. Acknowledge complexity honestly
4. Focus on "why", not just "what"
5. Never brag or oversell
6. Use precise, domain-specific terminology
7. Respect previous implementations - use neutral language

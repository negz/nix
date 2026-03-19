---
name: krm-api-design
description: Design Kubernetes Resource Model (KRM) APIs - CRDs and XRDs. Use when designing, reviewing, or evolving custom resource schemas, composite resource definitions, OpenAPI v3 schemas for Kubernetes, or when the user mentions CRD design, XRD design, API schema design, or asks how to structure fields in a Kubernetes API.
---

# KRM API Design

Help users design Kubernetes Resource Model APIs that are future-proof, clear to
consume, and follow established conventions. This applies to CRDs and Crossplane
XRDs equally -- an XRD schema is a thin wrapper on a CRD schema.

The goal is a great user experience for API consumers. Think about what it's like
to write YAML against this API, read it back six months later, and evolve it
without breaking anyone.

## Design for Evolution, Not Versioning

The most important principle: **design APIs that never need a new version.**

API designers see version strings like `v1alpha1` and assume the path to
evolution is introducing `v1alpha2` or `v1beta1`. This is a trap. CRD versions
are two views into the same stored data. All versions must be round-trippable
to the storage version and back without data loss. This means:

- You can rename or move a field across versions.
- You **cannot** add a new required field that doesn't exist in older versions.
- You **cannot** drop a field that was required by an older version.

Introducing a new version buys you surprisingly little. The better path is
designing an API that can evolve with purely additive, backward-compatible
changes. Kubernetes evolved Deployment v1 for 7+ years without needing v2.

## The Core Rules

### Use Required Fields Sparingly

Assume any required field can never be removed. Ask: does the user genuinely
need to express an opinion about this, or can the system pick a sensible default?

If a sensible default exists, make the field optional with an explicit default
value. Explicit defaults are important -- they make the full desired state
visible rather than hiding it behind "unspecified means default behavior".

### Prefer Enums Over Booleans

This is the single most common API design mistake. A boolean seems simple today
but almost always evolves into a set of options.

```yaml
# Bad: what happens when you need a third option?
spec:
  autoScaling: true

# Good: room to grow.
spec:
  scalingPolicy: Automatic  # Could later add Manual, Scheduled, etc.
```

Many ideas start as boolean but trend toward a small set of mutually exclusive
options. Use a PascalCase string enum from the start. The cost is trivial (a
string field instead of a bool). The benefit is avoiding a breaking change when
the third option inevitably arrives.

When you see yourself reaching for a bool, stop and think: is there a world
where this becomes three options? If there's even a chance, use an enum.

### If in Doubt, Use an Array

Could a field plausibly need multiple values in the future? Start with an array.

```yaml
# Risky: what if you need multiple regions later?
spec:
  region: us-east-1

# Safer: single-element arrays are fine.
spec:
  regions:
    - us-east-1
```

Worst case, 99% of users use a single-element array forever. Best case, you've
saved yourself and your users from a painful migration.

### Leave Room for Variants

This is the most valuable pattern for future-proofing an API. When there's any
chance a field or group of fields could have variants, use a **discriminator
field** paired with **variant subobjects**.

```yaml
# An AcmeDatabase that started PostgreSQL-only but now supports MySQL too.
apiVersion: platform.org/v1beta1
kind: AcmeDatabase
spec:
  engine: PostgreSQL
  postgresql:
    version: "17.1"
    maxConnections: 100
```

The discriminator (`engine`) toggles which subobject is active. When MySQL
support arrives, it's a purely additive change:

```yaml
spec:
  engine: MySQL
  mysql:
    version: "8.0"
    innodbBufferPoolSize: "4Gi"
```

This pattern appears throughout well-designed Kubernetes APIs:

| Discriminator | Variants | API |
|---|---|---|
| `mode` | `Pipeline` | Composition |
| `strategy` | `None`, `Webhook` | CRD conversion |
| `source` | `None`, `Secret` | FunctionCredentials |
| `provider` | `Cosign` | ImageConfig verification |

**Choose a good name for the discriminator.** `mode`, `policy`, `strategy`,
`engine`, `backend`, `system` all tell you something about the domain. `type` is
acceptable when nothing more descriptive fits, but reach for a domain-specific
name first.

**The discriminator should be a required enum.** The variant subobjects should be
optional, with CEL validation rules enforcing that the correct one is set:

```yaml
properties:
  engine:
    type: string
    enum: [PostgreSQL, MySQL]
  postgresql:
    type: object
    # ... postgresql-specific fields
  mysql:
    type: object
    # ... mysql-specific fields
x-kubernetes-validations:
  - rule: "self.engine == 'PostgreSQL' && has(self.postgresql)"
    message: "postgresql is required when engine is PostgreSQL"
  - rule: "self.engine == 'MySQL' && has(self.mysql)"
    message: "mysql is required when engine is MySQL"
```

Worst case, you never need a second variant and some fields are slightly more
nested than necessary. Best case, you've saved yourself a breaking change.

## Conditions

Conditions are the standard way to communicate status. Get them right.

- **Set conditions on first reconcile, even if status is Unknown.** This tells
  other components the controller exists and is making progress.
- **Provide a summary condition.** Use `Ready` for long-running resources,
  `Succeeded` for bounded-execution resources. Simple consumers query just this.
- **Name conditions as adjectives or past-tense verbs.** `Ready`, `Available`,
  `Succeeded`, `Failed` -- not present-tense verbs like `Deploying`.
- **Choose polarity that's clearest for humans.** Neither positive nor negative
  polarity is universally better. `MemoryExhausted` may be clearer than
  `SufficientMemory`. Avoid double negatives like `Failed=False`.
- **Reason is a one-word CamelCase identifier.** `BackendNotFound`, not
  `"the backend could not be found"`. Message is the human-readable sentence.
- **Conditions are a map list.** Use `x-kubernetes-list-type: map` with
  `x-kubernetes-list-map-keys: [type]`.

## Printer Columns

Define `additionalPrinterColumns` so `kubectl get` is immediately useful.

- Surface the most important condition statuses (e.g. `READY`, `SYNCED`).
- Show key spec fields that identify or distinguish instances (e.g. `PACKAGE`,
  `ENGINE`).
- Always include `AGE` as the last column.
- Use the jsonPath `$.status.conditions[?(@.type=='Ready')].status` pattern.

## Field Design

### Naming

- JSON field names are camelCase. Kind names are PascalCase singular. Resource
  plurals are all lowercase.
- Be declarative, not imperative. Name fields for what something **is**, not
  what it **does**.
- Include units when ambiguous: `timeoutSeconds`, `retryLimit`,
  `intervalMinutes`. Use `fooSeconds` for durations.
- Don't abbreviate unless extremely common (`id`, `args`). Acronyms should be
  uniform case: `httpGet` at field start, `TCP` as a constant.
- Reference fields: `fooRef` for object references, `fooName` for by-name
  references. Use `fooSelector` for label-selector-based references.

### Bounds and Validation

Every field needs bounds. This isn't optional -- unbounded fields are a DoS
vector and signal an unfinished API.

- All strings: `maxLength` (and `minLength` if appropriate).
- All numbers: `minimum` and `maximum`.
- All arrays: `maxItems` (and `minItems` if appropriate).
- All maps: `maxProperties`.
- All enums: explicit `enum` list with PascalCase values.
- Use `format` where applicable: `int32`, `int64`, `date-time`, `byte`.
- Use CEL `x-kubernetes-validations` for cross-field constraints, immutability
  (`self == oldSelf`), and conditional requirements.

### Lists

- Use lists of named subobjects, not maps of subobjects. The only exceptions
  are pure key-value maps (labels, annotations, data).
- Declare merge semantics on every list:
  - `x-kubernetes-list-type: map` with `x-kubernetes-list-map-keys` for
    merge-by-key (e.g. conditions by `type`, ports by `containerPort`).
  - `x-kubernetes-list-type: atomic` for replace-wholesale (e.g. enum lists,
    short names).

### References

- Namespaced resources should reference objects in the same namespace. Cross-
  namespace references breach security boundaries. If required, document the
  edge cases and add permission checks.
- For references that could be by-name or by-selector, provide both
  `resourceRef` and `resourceSelector` fields. Document that the ref takes
  precedence when both are set.

## Spec and Status

- **Spec is desired state. Status is observed state.** They have separate update
  paths via the `/status` subresource.
- **No extra top-level fields** beyond `spec`, `status`, and standard metadata.
  If a resource doesn't need status (its state can't vary from intent), you can
  omit status or rename spec to something domain-appropriate (e.g. `data`).
- **Spec fields are declarative.** They describe what the user wants, not what
  actions to take.

## CRD Metadata

- Put every resource in a **category** so `kubectl get <category>` works across
  all your resources. Choose a meaningful group-level category.
- Provide **short names** for resources users interact with frequently. Keep
  them lowercase, short, and intuitive.
- Write a **resource-level description** that explains what the resource is in
  one sentence, optionally followed by a link to documentation.
- Write clear **field-level descriptions** that explain semantics, constraints,
  and interactions with other fields -- not just what the field is called.

## Key Principles

1. Design for evolution, not versioning -- you get less from a new version than you think
2. Prefer enums over booleans -- the third option always arrives
3. Use the discriminator + subobject pattern to leave room for variants
4. Choose descriptive discriminator names: `mode`, `strategy`, `engine` over `type`
5. Start with arrays when multiple values are plausible
6. Use required fields sparingly -- assume they're permanent
7. Put bounds on everything: strings, numbers, arrays, maps
8. Declare list merge semantics explicitly on every list
9. Set conditions on first reconcile; provide a summary condition
10. Make `kubectl get` useful with printer columns that surface conditions and key fields

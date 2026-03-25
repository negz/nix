---
name: go-code-factoring
description: Factor and structure Go code for clarity, testability, and composability. Use when writing new Go code, refactoring existing code, reviewing code structure, adding interfaces, decomposing large functions or structs, or when the user mentions factoring, refactoring, architecture, or code organization. Also use before writing unit tests to ensure code is well structured.
---

# Go Code Factoring

## When to Use This Skill

Use this skill when:
- Writing new Go code (to get the structure right from the start)
- Refactoring existing code for clarity or testability
- Reviewing whether code is well structured
- Preparing code for unit testing (the `go-unit-tests` skill expects this)
- The user asks about Go architecture, decomposition, or design

## Working in Existing Codebases

Before applying any pattern from this skill, read the existing codebase. This
skill contains two kinds of guidance, and they should be treated differently:
the *what* (goals) and the *how* (mechanisms).

### Goals — apply broadly

The goals behind these patterns are good engineering in any Go codebase. Apply
them when writing new code or modifying existing code, regardless of whether the
surrounding code follows them:

- Keep interfaces small
- Wrap errors with context about what the current function was trying to do
- Don't leave dependencies nil — provide working defaults
- Avoid unexported methods when an exported function or injected dependency
  would be clearer
- Name packages for what they provide, not what they contain
- Keep dependency direction flowing downward

### Mechanisms — match the codebase

The specific mechanisms this skill recommends for achieving those goals are
opinionated choices among reasonable alternatives. When the codebase has an
established way of doing the same thing, match it.

Examples:
- This skill recommends functional options, but the codebase might use
  `(T, error)` constructors or plain struct initialization — both are fine ways
  to achieve "don't leave dependencies nil"
- This skill recommends consumer-side interfaces, but the codebase might define
  them alongside implementations
- This skill recommends `*Fn` adapters for single-method interfaces — don't
  introduce them if the codebase doesn't use them
- This skill recommends `fmt.Errorf("cannot X: %w", err)`, but the codebase
  might use `pkg/errors` or a different wrapping style — the goal is error
  context, not a specific function call

Consistency within a codebase matters more than any individual mechanism
preference.

### Improving code you're already changing

When you need to modify existing code — to add functionality, fix a bug, or
generalize behavior — it's fine to improve its structure as part of that change.
Extracting an interface from a concrete dependency you're already modifying, or
adding error context to a function you're already reworking, are natural
improvements.

What to avoid is refactoring for its own sake — rewriting working code that you
don't otherwise need to touch, or going on a crusade through neighboring files.
The scope of structural improvement should roughly match the scope of the
functional change.

## Think Like a Library Author

Write every package as if it will be published as a standalone library — even
internal packages that aren't intended for public consumption. This means:

- **Clear API surface.** Exported types and functions should make sense to
  someone who hasn't read the implementation. Godoc should be sufficient.
- **No implicit coupling.** A package should not assume it knows who's calling
  it. Accept interfaces, take configuration via options, return concrete types.
- **Self-contained.** A package should be extractable into its own module without
  surgery. If extracting it would require pulling half the codebase along, the
  boundaries are wrong.
- **Testable in isolation.** You should be able to write tests for a package
  without standing up the entire system. If you can't, the dependencies need
  rethinking.

This mindset naturally produces code that is self-documenting, reusable, and
composable. Most of the patterns below follow from it.

### Anti-patterns

The library-author test catches several common mistakes:

- **Constructor does wiring.** If your constructor takes a file path, config
  string, or DSN and constructs clients internally, the wiring belongs in
  `main`, not in the library. The constructor should accept the constructed
  dependencies. A `NewServer(kubeconfig string)` that internally loads config,
  creates transports, and builds clients is untestable without real
  infrastructure. A `NewServer(host string, transport http.RoundTripper, ...)` is
  testable with `httptest`.
- **Constructor returns error for assembly.** If the constructor only assigns
  dependencies to fields, it has nothing to fail on. Remove the error return.
  Constructors that return errors are a signal that they're doing work (I/O,
  validation, client creation) that belongs elsewhere.
- **Package imports infrastructure it doesn't need.** If a package imports a
  database driver, HTTP client library, or cloud SDK only to construct a
  dependency internally, that dependency should be injected instead. The package
  should define an interface for what it needs, and the caller provides the
  implementation.

## How to Apply This Skill

When factoring code, read the existing codebase first. Match its conventions. The
patterns below are guidelines — apply judgment based on context. Not every
function needs an interface, and not every struct needs functional options.

### Before you write

Before writing a new package, answer these questions:

1. **What are this package's dependencies?** List every external thing it needs
   (database, HTTP client, logger, other packages). For each one: is it required
   or optional? Does it do I/O?
2. **Which dependencies need interfaces?** Any dependency that does I/O or has
   side effects needs an interface at the consumer — the caller will need to
   inject a fake for testing.
3. **What's required vs optional?** Required dependencies are positional
   constructor parameters. Optional dependencies (logger, metrics, HTTP client)
   get functional options with nop/default implementations.
4. **What should be exported?** Package-level functions that accept and return
   standard types (`http.Handler`, `http.RoundTripper`, `io.Reader`) are
   reusable building blocks — export them. Unexport only when a function is
   genuinely tied to internal state that shouldn't be exposed.

## Interfaces

### Define Interfaces Where They're Consumed

Define interfaces in the file that uses them, not alongside the implementation.
Keep them small — one to three methods. If an interface has more than five
methods, it's likely too broad.

```go
// In reconciler.go — the file that calls these methods.
type Fetcher interface {
    Fetch(ctx context.Context, id string) (Record, error)
}

type Publisher interface {
    Publish(ctx context.Context, r Record) error
}
```

The implementation lives elsewhere. It doesn't need to know about the interface.

### Function Type Adapters

For every single-method interface, define a matching function type that satisfies
it. This is the single most useful Go pattern for composability and testability.

```go
type FetcherFn func(ctx context.Context, id string) (Record, error)

func (fn FetcherFn) Fetch(ctx context.Context, id string) (Record, error) {
    return fn(ctx, id)
}
```

This enables:
- Inline implementations without a struct: `FetcherFn(func(...) { ... })`
- Trivial nop defaults: `FetcherFn(func(...) (Record, error) { return Record{}, nil })`
- Direct use as test fakes without a mock struct

Always define the `*Fn` type alongside the interface it satisfies. They're a
pair.

### Interface Composition

Build larger roles from small interfaces by embedding, not by defining one big
interface.

## Constructors and Functional Options

### The Shape

Required dependencies are positional parameters. Optional dependencies are
functional options. The constructor sets defaults before applying options. Always
return a concrete pointer type.

```go
type ProcessorOption func(*Processor)

func WithLogger(l Logger) ProcessorOption {
    return func(p *Processor) { p.log = l }
}

func NewProcessor(s Store, o ...ProcessorOption) *Processor {
    p := &Processor{
        store:   s,                 // required
        log:     NewNopLogger(),    // default — never nil
        timeout: 30 * time.Second,  // default
    }
    for _, fn := range o {
        fn(p)
    }
    return p
}
```

### Nop Defaults

Optional dependencies must default to a working no-op implementation, never nil.
If a dependency is a `Logger`, default to a `NopLogger`. If it's a `Recorder`,
default to a `NopRecorder`. This eliminates nil checks throughout the code.

### When to Use Functional Options

Use functional options when:
- The struct has optional dependencies (logger, metrics, recorder)
- Tests need to inject mocks for specific dependencies
- There are sensible defaults for most fields

Don't use them when:
- All fields are required (use positional parameters)
- The struct is simple with 1-2 fields (construct directly)

## Struct Decomposition

### Group Related Interfaces into Sub-Structs

When a struct has many dependencies, group related ones into unexported
sub-structs. This avoids flat bags of 10+ fields and makes method calls read
like prose: `p.in.Fetch(ctx, id)`, `p.out.Publish(ctx, r)`.

### Prefer Exported Functions Over Private Methods

Avoid unexported methods on structs. They can't be swapped, can't be mocked, and
can't be reused. Instead:

- **Extract to an injected interface** if the logic represents a swappable step.
- **Extract to a package-level function** if the logic is pure computation that
  doesn't need the struct's state.
- **Leave it inline** in the main method if it's short and only used once.

This applies equally to package-level functions. Default to exporting
package-level functions that accept and return standard types (`http.Handler`,
`http.RoundTripper`, `fs.FS`, `io.Reader`). These are reusable building blocks.
A convenience constructor like `NewServer` can assemble them, but the pieces
should be independently usable.

Unexport a function only when you've decided it shouldn't be part of the
package's API — not because you haven't thought about it.

## Composable Behavior

Chain types and decorators enable composable behavior without modifying existing
implementations. See [references/example.md](references/example.md) for full
examples of both patterns.

**Chain types**: a slice that implements the same interface by iterating.
`SenderChain[]` tries each sender in order for fallback delivery.

**Decorators**: a wrapper that adds cross-cutting behavior (logging, caching,
metrics) to an interface. Put them in child packages to keep dependency direction
clean.

## Error Wrapping

Wrap errors at every return point with context about what the current function
was trying to do. Use inline strings with a consistent verb-first style:

```go
r, err := p.store.Get(ctx, id)
if err != nil {
    return fmt.Errorf("cannot get record: %w", err)
}
```

The "cannot X" prefix style builds readable error chains:
`cannot process record: cannot get record: connection refused`

Keep error strings inline at the call site. Don't extract them into package-level
constants (`const errGet = "cannot get record"`). The constant adds a level of
indirection that makes the code harder to read without adding value — the string
is only used in one place, and the constant name just restates the string. Error
constants were a pattern in older Crossplane code but are no longer preferred.

Match the project's error wrapping convention — whether that's `fmt.Errorf` with
`%w`, a `pkg/errors`-style library, or something else. Check existing code.

## Naming

### Packages

- Single word, lowercase, singular: `cache`, `engine`, `circuit`, `version`.
- Name packages for what they provide, not what they contain.
- Avoid `util`, `helper`, `common`, `base` — they're magnets for unrelated code.

### Functions and Methods

- Constructors: `New` prefix — `NewProcessor`, `NewStore`.
- Actions: verb-first — `Fetch`, `Validate`, `Publish`, `RunFunction`.
- Predicates: `Is` prefix — `IsValid`, `IsReady`.
- Derivation: `For` prefix — `ForRecord`, `ForUser`.

### Receivers

Use the first letter of the type name. Two letters for two-word types.

```go
func (p *Processor) Process(...)   // p for Processor
func (fc FetcherChain) Fetch(...)  // fc for FetcherChain
```

### Variables and Parameters

Short names in tight scope, descriptive names in wider scope.

When a parameter's type already communicates its purpose, use a short name.
Repeating the type in the name is stuttering:

```go
// Good — the type explains the role.
func NewServer(host string, transport http.RoundTripper, er EndpointResolver) *Server
func NewChatProxy(log *slog.Logger, er EndpointResolver, client *http.Client) http.Handler

// Bad — the names just restate the types.
func NewServer(kubeHost string, kubeTransport http.RoundTripper, resolver EndpointResolver) *Server
func NewChatProxy(log *slog.Logger, endpointResolver EndpointResolver, httpClient *http.Client) http.Handler
```

Use a descriptive name only when the type is ambiguous. A function taking two
`string` parameters needs names to distinguish them: `host string, path string`.
A function taking one `http.RoundTripper` does not: `transport` is already clear
from the type.

### Named Types for Clarity

Use named types to prevent mixing up values of the same underlying type.

```go
type UserID string
type TeamID string
```

## Dependency Direction

Dependencies flow in one direction — down, never up. A package should never
import its parent or its siblings. If two packages need to share a type, move it
to a common ancestor.

In practice this means the package that orchestrates a workflow defines the
interfaces it depends on, and implementation packages satisfy them via structural
typing without importing the orchestrator. A separate `main` or wiring package
imports both and connects them.

```
myapp/
├── server/       # Defines a Storage interface, uses it to handle requests
├── postgres/     # Implements server.Storage (without importing server)
└── cmd/myapp/    # Imports both, wires postgres into server
```

## Complete Example

See [references/example.md](references/example.md) for a full worked example
showing a well-factored package with interfaces, function type adapters,
functional options, sub-struct grouping, a chain type, and a decorator.

## When to Create Interfaces

Create an interface when you need a seam — a point where you can swap in a
different implementation. The most common reason is testability: if a dependency
does I/O, has side effects, or is slow/expensive, you'll want to mock it when
testing the caller. Write code that's testable from the start.

You don't need a strong idea of what other real implementations might exist.
Sometimes there's only ever the production implementation and a mock. That's
fine — the interface is earning its keep by making the caller testable.

Conversely, if a dependency is pure computation — data transformations,
formatting, validation logic with no I/O — the caller can test with real inputs
and outputs. An interface just adds indirection without value.

## After You Write

After finishing a package, review it against these questions:

1. **Can I construct the main type without real I/O?** If the constructor needs
   a kubeconfig, database DSN, or network address to succeed, the wiring belongs
   in `main`. The constructor should accept pre-built dependencies.
2. **Can I test every exported function with fakes?** If a function can only be
   tested against real infrastructure, it's missing an interface.
3. **Does every dependency come from a parameter?** If a function reads from a
   package-level variable or calls a global (`http.DefaultClient`, `os.Getenv`),
   that dependency should be injected instead.
4. **Are unexported functions unexported by design or by default?** Every
   unexported package-level function should be a deliberate choice. If it takes
   and returns standard types, it's probably a reusable building block that
   should be exported.
5. **Do any parameter names stutter with their types?** If removing the name and
   reading just the type signature still makes sense, the name is redundant.

## Key Principles

1. Write every package like a library — self-contained, documented, extractable
2. Interfaces at the consumer, not the implementer
3. `*Fn` adapters for every single-method interface
4. Functional options for optional dependencies, nop defaults for all of them
5. Group related interfaces into sub-structs on the orchestrator
6. One primary method per orchestrating struct
7. Chain types and decorators for composable behavior
8. Wrap errors inline at the call site with verb-first context
9. Prefer exported functions — unexport by decision, not by default
10. Dependencies flow downward — never import up or sideways
11. Don't abstract what doesn't need abstracting

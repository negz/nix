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

## How to Apply This Skill

When factoring code, read the existing codebase first. Match its conventions. The
patterns below are guidelines — apply judgment based on context. Not every
function needs an interface, and not every struct needs functional options.

Before making changes, identify:
1. What are the dependencies? Which are required, which are optional?
2. What are the behavioral seams? Where might you want to swap implementations?
3. Is the code testable? Can you inject mocks for external dependencies?
4. Does the code read clearly? Can you understand the high-level flow without
   reading every helper?

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

```go
type Reader interface {
    Read(ctx context.Context, id string) (Record, error)
}

type Writer interface {
    Write(ctx context.Context, r Record) error
}

type ReadWriter interface {
    Reader
    Writer
}
```

Or compose interfaces into an unexported sub-struct on a struct (see Struct
Decomposition below).

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

func WithTimeout(d time.Duration) ProcessorOption {
    return func(p *Processor) { p.timeout = d }
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

Define `Nop` types as zero-value structs that satisfy the relevant interface:

```go
type NopLogger struct{}

func (NopLogger) Info(string, ...any) {}
```

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
like prose.

```go
type input struct {
    Fetcher
    Validator
}

type output struct {
    Publisher
    Notifier
}

type Processor struct {
    in     input
    out    output
    log    Logger
}
```

Now method calls read clearly: `p.in.Fetch(ctx, id)`, `p.out.Publish(ctx, r)`.

Functional options can target into sub-structs:

```go
func WithPublisher(pub Publisher) ProcessorOption {
    return func(p *Processor) { p.out.Publisher = pub }
}
```

### Prefer Exported Methods and Free Functions Over Private Methods

Avoid unexported methods on structs. They can't be swapped for alternative
implementations, can't be mocked when testing the methods that call them, and
can't be reused by other types. Instead:

- **Extract to an injected interface** if the logic represents a swappable step.
- **Extract to a package-level function** if the logic is pure computation that
  doesn't need the struct's state.
- **Leave it inline** in the main method if it's short and only used once.

A well-factored struct typically has one primary exported method and zero private
methods. The steps of the workflow are calls to injected dependencies, not calls
to `self`.

```go
// Prefer this — steps are injected, each independently testable.
func (p *Processor) Process(ctx context.Context, id string) error {
    r, err := p.in.Fetch(ctx, id)
    if err != nil {
        return fmt.Errorf("cannot fetch record: %w", err)
    }
    if err := p.in.Validate(r); err != nil {
        return fmt.Errorf("cannot validate record: %w", err)
    }
    return p.out.Publish(ctx, r)
}

// Avoid this — private methods can't be mocked or swapped.
func (p *Processor) Process(ctx context.Context, id string) error {
    r, err := p.fetch(ctx, id)    // unexported method
    if err != nil {
        return err
    }
    return p.publish(ctx, r)      // unexported method
}
```

## Composable Behavior

### Chain Types

When multiple implementations of an interface should run in sequence, define a
chain type — a slice that implements the same interface by iterating.

```go
type ValidatorChain []Validator

func (vc ValidatorChain) Validate(r Record) error {
    for _, v := range vc {
        if err := v.Validate(r); err != nil {
            return err
        }
    }
    return nil
}
```

Chain types compose cleanly: `NewProcessor(store, WithValidator(ValidatorChain{v1, v2, v3}))`.

They also work for aggregation (not just short-circuit). A chain that merges
results from multiple sources:

```go
type FetcherChain []Fetcher

func (fc FetcherChain) Fetch(ctx context.Context, id string) (Record, error) {
    var result Record
    for _, f := range fc {
        r, err := f.Fetch(ctx, id)
        if err != nil {
            return Record{}, err
        }
        result = merge(result, r)
    }
    return result, nil
}
```

### Decorators

When you need to add cross-cutting behavior (caching, logging, metrics) to an
interface, wrap it in a decorator that implements the same interface.

```go
type LoggingFetcher struct {
    wrapped Fetcher
    log     Logger
}

func (f *LoggingFetcher) Fetch(ctx context.Context, id string) (Record, error) {
    f.log.Info("fetching record", "id", id)
    r, err := f.wrapped.Fetch(ctx, id)
    if err != nil {
        f.log.Info("fetch failed", "id", id, "error", err)
    }
    return r, err
}
```

If decorators grow complex, put them in child packages:

```
processor/
├── processor.go         # Core logic + interfaces
├── cached/
│   └── cached.go        # Caching decorator
└── logged/
    └── logged.go        # Logging decorator
```

Each child package imports the parent's interface and returns a struct satisfying
it. The parent never imports the children.

## Error Wrapping

Wrap errors at every return point with context about what the current function
was trying to do. Use a consistent verb-first style.

```go
r, err := p.store.Get(ctx, id)
if err != nil {
    return fmt.Errorf("cannot get record: %w", err)
}
```

The "cannot X" prefix style builds readable error chains:
`cannot process record: cannot get record: connection refused`

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

### Variables

Short names in tight scope, descriptive names in wider scope.

```go
// Tight scope — single letter is fine.
for i, r := range records {
    // ...
}

// Wider scope — be descriptive.
fetchTimeout := 30 * time.Second
```

### Named Types for Clarity

Use named types to prevent mixing up values of the same underlying type.

```go
type UserID string
type TeamID string

// This is self-documenting and type-safe.
type Membership struct {
    User UserID
    Team TeamID
}
```

Use named types as map keys to make the map's semantics explicit:
`map[UserID]Record` rather than `map[string]Record`.

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

`server` doesn't know about `postgres`. `postgres` doesn't know about `server`.
`cmd/myapp` imports both and passes a `postgres.Store` to `server.New`.

## Complete Example

See [references/example.md](references/example.md) for a full worked example
showing a well-factored package with interfaces, function type adapters,
functional options, sub-struct grouping, a chain type, and a decorator.

## When to Create Interfaces

Create an interface when you need a seam — a point where you can swap in a
different implementation. The most common reason is testability: if a dependency
does I/O, has side effects, or is slow/expensive, you'll want to mock it when
testing the caller. Don't wait until you write the tests to discover you need
the seam. Write code that's testable from the start.

You don't need a strong idea of what other real implementations might exist.
Sometimes there's only ever the production implementation and a mock. That's
fine — the interface is earning its keep by making the caller testable.

Conversely, if a dependency is pure computation — data transformations,
formatting, validation logic with no I/O — the caller can test with real inputs
and outputs. An interface just adds indirection without value.

## Key Principles

1. Write every package like a library — self-contained, documented, extractable
2. Interfaces at the consumer, not the implementer
3. `*Fn` adapters for every single-method interface
4. Functional options for optional dependencies, nop defaults for all of them
5. Group related interfaces into sub-structs on the orchestrator
6. One primary method per orchestrating struct
7. Chain types and decorators for composable behavior
8. Wrap errors at every return with verb-first context
9. Prefer exported methods and free functions over private methods on structs
10. Dependencies flow downward — never import up or sideways
11. Don't abstract what doesn't need abstracting

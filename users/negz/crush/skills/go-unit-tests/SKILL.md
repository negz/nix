---
name: go-unit-tests
description: Write unit tests for Go code. Use when creating, adding, or updating Go tests, writing table-driven tests, creating mocks or fakes, adding test coverage, or when the user mentions testing, cmp.Diff, assertions, or test cases. Also use when reviewing whether code is testable.
---

# Go Unit Tests

## When to Use This Skill

Use this skill when the user asks to:
- Write, add, or update unit tests for Go code
- Create mocks or fakes for interfaces
- Improve test coverage
- Review whether code is structured for testability

## Existing Codebase Conventions Take Precedence

Before writing any tests, read the existing test files in the package and its
neighbors. If the codebase already has established testing patterns, follow them
— even if they differ from what this skill describes.

Signs that the codebase uses different conventions:
- Tests use testify (`assert.*`, `require.*`, `suite.*`)
- Tests use `[]struct` with a `name` field instead of `map[string]struct`
- Tests use gomock, mockgen, counterfeiter, or other codegen mocks
- Tests use `reflect.DeepEqual` instead of `cmp.Diff`
- Tests use black-box testing (`package foo_test`)

If you see any of these, match the existing style. Consistency within a codebase
is more important than following this skill's preferences. These patterns are
opinionated defaults for greenfield code and codebases that already use them (or
something very close). They are not meant to override a codebase's established
practices.

When the codebase is close but not identical — say it uses `cmp.Diff` but with
`[]struct` instead of `map[string]struct` — follow the codebase. Don't
selectively adopt pieces of this skill.

## IMPORTANT: Factor Code Before Testing

Before writing tests for a package, run the `go-code-factoring` skill on it.
Tests are expensive to write and expensive to throw away. Well-factored code
with clear interfaces is a prerequisite for useful tests.

If the `go-code-factoring` skill has not yet been run on the package under
test, run it first. If the user asks you to skip factoring, proceed — but
note that tests may need rewriting if the code is later restructured.

## Test File Organization

- Place tests in the **same package** as the code (white-box testing). Use
  `package foo`, not `package foo_test`.
- Name test files `*_test.go` alongside the source file they test.
- Define mocks at the top of the test file, above test functions.

## Table-Driven Tests

Every test uses this structure. Do not deviate.

```go
func TestFunctionName(t *testing.T) {
	type args struct {
		// inputs to the function under test
	}
	type want struct {
		// expected outputs
	}

	cases := map[string]struct {
		reason string
		args   args
		want   want
	}{
		"DescriptivePascalCaseName": {
			reason: "A sentence explaining what behavior this case verifies.",
			args:   args{...},
			want:   want{...},
		},
	}

	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			got, err := FunctionName(tc.args.input)

			if diff := cmp.Diff(tc.want.err, err, cmpopts.EquateErrors()); diff != "" {
				t.Errorf("\n%s\nFunctionName(...): -want error, +got error:\n%s", tc.reason, diff)
			}
			if diff := cmp.Diff(tc.want.result, got); diff != "" {
				t.Errorf("\n%s\nFunctionName(...): -want, +got:\n%s", tc.reason, diff)
			}
		})
	}
}
```

### Structural Rules

- **Always `map[string]struct`**, never `[]struct` with a name field.
- **Always include a `reason` field.** A human sentence explaining *why* this
  case matters. Not a restatement of the case name.
- **PascalCase case names.** Descriptive of the scenario: `"ShortName"`,
  `"GetRevisionError"`, `"MissingNamespace"`.
- **Separate `args` from `want`.** If the function under test is a method on an
  object that needs construction, add a `params` struct for constructor
  dependencies alongside `args` for method inputs.
- **No per-case setup or teardown.** All dependencies are mocks injected via
  struct fields. Object construction happens inside `t.Run`.

### Assertions

Use `cmp.Diff` from `github.com/google/go-cmp/cmp` for all comparisons.

```go
import (
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
)
```

The assertion format is always:

```go
if diff := cmp.Diff(want, got, opts...); diff != "" {
	t.Errorf("\n%s\nFunctionName(...): -want, +got:\n%s", tc.reason, diff)
}
```

The leading `\n` before `%s` ensures the reason starts on its own line.

Useful `cmp` options:
- `cmpopts.EquateErrors()` — compare errors using `errors.Is` semantics.
- `cmpopts.AnyError` — match any non-nil error in the `want` struct.
- `cmpopts.EquateEmpty()` — treat nil and empty slices/maps as equal.
- `cmpopts.SortSlices(less)` — order-independent slice comparison.
- `cmp.AllowUnexported(T{})` — compare unexported fields of type T.

### Error Handling in Tests

Use `cmpopts.EquateErrors()` for all error comparisons. Use `cmpopts.AnyError`
when only the presence of an error matters, not the specific value.

Match the project's error wrapping convention — whether that's `fmt.Errorf` with
`%w`, a `pkg/errors`-style library, or something else. Check existing code and
follow the same pattern. What matters is that `cmpopts.EquateErrors()` uses
`errors.Is`, so wrapped errors must support unwrapping.

Define a sentinel error at the top of the test file for generic error injection:

```go
var errBoom = errors.New("boom")
```

## Mocks

All mocks are hand-written. No codegen tools (no gomock, no mockgen, no
counterfeiter, no testify/mock).

### Functional Mock Structs

For multi-method interfaces, define a struct with `Mock`-prefixed function
fields. Each method delegates to the corresponding field.

```go
var _ SomeInterface = &MockSomething{}

type MockSomething struct {
	MockDoThing  func(ctx context.Context, name string) error
	MockGetStuff func() ([]Item, error)
}

func (m *MockSomething) DoThing(ctx context.Context, name string) error {
	return m.MockDoThing(ctx, name)
}

func (m *MockSomething) GetStuff() ([]Item, error) {
	return m.MockGetStuff()
}
```

Write constructor helpers for common return values:

```go
func NewMockDoThingFn(err error) func(context.Context, string) error {
	return func(_ context.Context, _ string) error { return err }
}
```

Rules:
- **Compile-time interface check**: `var _ Interface = &Mock{}`
- **`Mock` prefix** on function fields: `MockDoThing`, `MockGetStuff`.
- **Constructor helpers** named `NewMock<Method>Fn`.

### Function Type Adapters

For single-method interfaces, prefer a named function type in production code:

```go
type DoerFn func(ctx context.Context) error

func (fn DoerFn) Do(ctx context.Context) error { return fn(ctx) }
```

These double as inline test mocks — no separate mock struct needed.

### Partial Mocking via Embedding

When you only need to mock a few methods of a large interface, embed it:

```go
type MockBigThing struct {
	BigInterface // embed; unimplemented methods panic — that's the point

	MockTheMethodWeTest func() error
}
```

### Where to Put Mocks

- **Test-local mocks**: at the top of the `_test.go` file that uses them.
- **Shared mocks**: in a `fake/` subpackage alongside the production package.
  Use when multiple packages need the same mock.

## Dependency Injection in Tests

Prefer **functional options** (`With*` functions) for injecting mocks:

```go
r := NewReconciler(mgr,
	WithClient(tc.args.client),
	WithLogger(testLog),
)
```

If the code under test doesn't support functional options, construct the struct
directly and set exported fields. If there are no exported fields or options,
the code may not be testable yet — this is a factoring concern.

## Test Data

Put YAML/JSON fixtures in a `testdata/` directory alongside the test file.
Load with `os.ReadFile` or `//go:embed`.

## Do Not

These apply when writing tests in this skill's style. If the codebase uses
different conventions, follow those instead (see above).

- **Use testify.** No `assert.*`, no `require.*`, no `suite.*`.
- **Use `reflect.DeepEqual`.** Always `cmp.Diff`.
- **Use mock codegen.** No gomock, mockgen, counterfeiter.
- **Use `t.Fatal`/`t.FailNow`** in table-driven subtests unless the failure
  genuinely prevents remaining assertions in that subtest from running. Prefer
  `t.Errorf` to report and continue.
- **Construct errors inconsistently.** Match the project's error convention.
- **Skip the `reason` field.** Every case needs one.

## Edge Cases

- **Unexported functions**: Test them through the exported API when possible. If
  that's impractical, test directly — the tests are in the same package.
- **No interface to mock**: If the dependency is a concrete type with no
  interface, extract an interface at the call site. This is a factoring change —
  flag it to the user before proceeding.
- **Error paths**: Every function that returns an error should have at least one
  case that exercises the error path. Use `errBoom` and `cmpopts.AnyError`.

## Complete Example

See [references/example.md](references/example.md) for a full worked example
showing a production function, its interface, mock, and complete test.

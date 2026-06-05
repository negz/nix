# negz Review Conventions Reference

Verbatim conventions, the sources negz cites, and real example phrasings. Load
this when you need the exact rule or a link to cite. Quotes are drawn from his
actual review comments.

## Canonical sources to cite

| Topic | Link |
|---|---|
| Kubernetes API conventions (optional/required, spec/status, etc.) | https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md |
| Go Code Review Comments | https://go.dev/wiki/CodeReviewComments |
| Effective Go | https://go.dev/doc/effective_go |
| Go package naming | https://go.dev/blog/package-names |
| crossplane-runtime errors | https://pkg.go.dev/github.com/crossplane/crossplane-runtime/v2/pkg/errors |
| go-cmp (Diff, cmpopts.EquateEmpty, AllowUnexported) | https://pkg.go.dev/github.com/google/go-cmp/cmp |
| crossplane-runtime logging | https://pkg.go.dev/github.com/crossplane/crossplane-runtime/pkg/logging |
| Hyrum's Law (for API-stability arguments) | https://www.hyrumslaw.com |
| Semantic versioning | https://semver.org |

When citing, link the source and let it carry the weight, rather than asserting a
bare preference. negz includes a link in ~14% of comments.

## Go conventions

### Errors

- In a Crossplane project, use the crossplane-runtime errors package
  (`github.com/crossplane/crossplane-runtime/v2/pkg/errors`), not `fmt.Errorf` and
  not `github.com/pkg/errors`. It provides `Wrap`/`Wrapf`/`New`/`Errorf` with
  consistent error wrapping. Outside a Crossplane project, stdlib `errors` and
  `fmt.Errorf("...: %w", err)` are fine.
  > "Can we use `errors.Wrapf` instead of `fmt.Errorf`? We mostly use the
  > crossplane-runtime errors package throughout the Crossplane codebases."
- `errors.Wrap(err, msg)` returns `nil` when `err` is `nil`. So this:
  ```go
  err := doThing()
  if err != nil {
      return errors.Wrap(err, errDoThing)
  }
  return nil
  ```
  collapses to `return errors.Wrap(doThing(), errDoThing)`.
  > "Nit: This could be simplified. `errors.Wrap` will return `nil` if the
  > wrapped error is `nil`."
- `Wrapf` only when the message contains formatting verbs; otherwise `Wrap`.
  > "Nit: Wrapf is only necessary when there's string formatting in the error
  > string."
- Use `Wrap` over `WithMessage` (Wrap adds the stack trace).
- For utility functions, prefer wrapping context onto the error and returning it,
  trusting a higher-level caller to log — don't log and return.
- `errors.Cause` / `resource.Ignore(pred, err)` to handle/unwrap specific errors.

### Panic vs return error

Panic (don't return an error) when the failure is programmer error or a
fundamentally broken binary that could never work — e.g. `AddToScheme` failing at
startup, an impossible type assertion.
> "I typically feel like it's appropriate to panic rather than return an error in
> these cases where a binary is fundamentally broken due to programmer error."

### Interfaces and coupling

- Accept interfaces, return structs.
  > "generally I prefer the 'accept interfaces, return structs' pattern. I'm not
  > a fan of using 'go to definition' in my IDE ... only to find it's returning
  > an interface and I need to dig further to find the real implementation."
- Accept the smallest interface that does the job (`Cluster` not `Manager`; a
  narrow applicator not the full client) — also easier to fake in tests.
- Don't leak another package's types/options through your public API. Add your
  own option/abstraction that you control, so future breaking changes in the
  dependency don't break your callers (Hyrum's Law).

### Naming

- No underscores in func/test names: `TestWorkspaceApply`, not
  `TestWorkspace_Apply`. (CONTRIBUTING references prefer-table-driven-tests.)
- No camelCase in package names (and thus import names): prefer `sdkerrors` style
  only if lowercase; cite https://go.dev/blog/package-names.
- Name booleans/maps as predicates so reads are sentences: `if satisfied[dep]`,
  `ready[dep] = true`.
- Disambiguate from adjacent concepts: `templateName` not `name` near
  `metadata.name`; `EnableWebhooks`/`ENABLE_WEBHOOKS` when there's more than one.
- Match the convention's intent: `verbsUpdate` for "verbs that allow update", not
  "verbsOwnerReference" for "verbs used by owner references".

## Testing conventions

- Table-driven tests are the convention. Move loops over cases into the test;
  one entry per scenario.
  > links CONTRIBUTING.md#prefer-table-driven-tests
- Include a `reason string` in each case — documents intent and prints on failure.
  > "We have a convention ... of including a `reason` string in each test case
  > that captures this kind of data, both as documentation for test readers and
  > as something that can be printed if the test fails."
- Compare with `cmp.Diff(want, got)` and assert `!= ""`. Not `reflect.DeepEqual`
  (inconsistent output), not `cmp.Equal` for assertions.
  > "Why use `cmp.Equal` here (and elsewhere)? Could you use the typical
  > `cmp.Diff(...) != ""` pattern instead?"
  - Compare errors with `cmpopts.EquateErrors()`. Use `cmpopts.EquateEmpty()` for
    nil-vs-empty, `cmp.AllowUnexported` only when unavoidable (it's bad practice).
  - Express an expected error as `err: cmpopts.AnyError` (matched by
    `cmpopts.EquateErrors()`) to assert that *an* error occurred. Reconstruct the
    exact wrapped error in the want only when the specific error value is part of
    the contract.
- Don't unit-test trivial constructors.
- Put test-only helpers and scheme registrations in the test file, not prod code.
- New code paths — especially error/requeue paths — need test coverage.
- Tests use the table-driven style, not gomega.

## Logging conventions

- Use the crossplane-runtime `logging` package, structured.
- There is intentionally no `Error` method; include the error as a structured
  field: `log.Debug("...", "error", err)`.
  > "the convention is to include `\"error\", err` in the structured log
  > arguments."
- Don't log a value unless it's present (e.g. only log a diff when non-empty).
- Keep loggers at the reconciler level; pass errors *up* rather than plumbing
  loggers *down* into implementations.

## Reconciler / controller conventions

- On error, follow the usual pattern: set the `ReconcileError` (or relevant)
  condition, emit an event, write a debug log, and requeue — rather than
  returning a raw error and getting a tight requeue loop with bad backoff.
- Match the newest/canonical reconciler in the repo when updating tests or logic
  ("latest and greatest pattern from the XR reconciler tests").
- Rely on CRD schema defaulting and runtime guarantees instead of re-checking
  non-nil values the framework already guarantees.

## Kubernetes / KRM API conventions

- Optional fields: pointer + `+optional` + `,omitempty`. Required: not.
  Cite api-conventions.md#optional-vs-required.
- `spec` = desired state (user writes). `status` = observed state (read-only to
  the user). Don't carry vendor "READ-ONLY" notes into status field docs — every
  status field is read-only from the user's view, so the note just confuses.
- Use status conditions and standard condition reasons.
- Terminology, in code and docs:
  - A resource of `kind: Foo` is a **custom resource**, not a "CRD".
  - A **CRD** is the *definition*; an instance of the definition is the resource.
  > "Anything of `kind: MySQLInstance` is a (custom) resource, not a CRD."
- Breaking vs not: adding an optional field is non-breaking; changing field
  types, JSON casing, function/return signatures, or metric names is breaking.
  > "Changing this return signature will be a breaking change for all provider
  > implementations."
- Below v1.0, a reasonable compatibility compromise: don't break compatibility on
  a patch release; deprecation on a patch is OK; trivial behaviour changes on a
  patch are (subjectively) OK.

## Documentation conventions

- Wrap Markdown at 80 chars; don't mix wrapped/unwrapped in one file. It makes
  raw text readable and lets reviewers comment on specific lines. (rewrap plugin
  for VS Code automates it.)
- Comments/Godoc explain *why*, not *what*. Add a comment when intent is
  non-obvious (why a linter is disabled, why a no-op exists, a documented API
  limitation). Remove comments that restate obvious code.
  > "This is a case where I feel the comment explains something that is quite
  > obvious from how the code reads."
- Exported symbols need Godoc; don't document a public symbol by referencing a
  private one (pkg.go.dev readers can't see it).
- Right level of detail for the audience — link to the spec for internals rather
  than inlining implementation detail in user docs or help strings.

## Example phrasings (match this tone)

Questions (soft, assume author has context):
- "Do we need this branch / check / assignment?"
- "Is there a reason we make a new context here rather than using `ctx`?"
- "Should this be `resource.Status` to match `ManagedResourceSpec`?"
- "What do you think about naming this `Diff`?" / "WDYT about ...?"
- "Will these always be non-nil? Could this nil-pointer panic?"

Alternatives:
- "Nit: 'custom resource' rather than 'instance of a CRD'?"
- "I'd prefer we honor deletion policy even in observe-only mode."
- "Rather than interacting with the filesystem directly, consider afero so we can
  inject a fake in tests."

Holding opinions loosely:
- "I don't feel super strongly, but ..."
- "Either way is fine."
- "It's arguably less readable than what you have already though."

Suggestion blocks (for small mechanical fixes), use GitHub's syntax:
```suggestion
	return errors.Wrap(err, errGetSecret)
```

Acknowledgement:
- "Good catch." / "Nice." / "Looks good to me once the failing test is fixed."

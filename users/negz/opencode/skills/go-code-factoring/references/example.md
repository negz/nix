# Complete Example

A notification delivery package showing interfaces at the consumer, `*Fn`
adapters, functional options with nop defaults, sub-struct grouping, a chain
type, a decorator, and no private methods.

## Package Structure

```
notify/
├── notify.go          # Interfaces, types, Dispatcher
└── logged/
    └── logged.go      # Logging decorator for Sender
```

## `notify/notify.go`

```go
// Package notify dispatches notifications to users.
package notify

import (
	"context"
	"fmt"
	"log/slog"
)

// A Resolver maps a user ID to a delivery address.
type Resolver interface {
	Resolve(ctx context.Context, userID string) (string, error)
}

// A ResolverFn is a function that satisfies Resolver.
type ResolverFn func(ctx context.Context, userID string) (string, error)

// Resolve calls fn.
func (fn ResolverFn) Resolve(ctx context.Context, userID string) (string, error) {
	return fn(ctx, userID)
}

// A Sender delivers a message to an address.
type Sender interface {
	Send(ctx context.Context, address string, msg Message) error
}

// A SenderFn is a function that satisfies Sender.
type SenderFn func(ctx context.Context, address string, msg Message) error

// Send calls fn.
func (fn SenderFn) Send(ctx context.Context, address string, msg Message) error {
	return fn(ctx, address, msg)
}

// A Formatter renders a notification into a deliverable message.
type Formatter interface {
	Format(n Notification) (Message, error)
}

// A FormatterFn is a function that satisfies Formatter.
type FormatterFn func(n Notification) (Message, error)

// Format calls fn.
func (fn FormatterFn) Format(n Notification) (Message, error) { return fn(n) }

// A Logger logs operational messages.
type Logger interface {
	Info(msg string, args ...any)
}

// NopLogger is a Logger that does nothing.
type NopLogger struct{}

// Info does nothing.
func (NopLogger) Info(string, ...any) {}

// Notification is a notification to be delivered.
type Notification struct {
	UserID  string
	Subject string
	Body    string
}

// Message is a formatted, deliverable message.
type Message struct {
	Subject string
	Body    string
}

// SenderChain is a Sender that tries each sender in order, returning on the
// first success. This is useful for fallback delivery (e.g. try email, then
// SMS).
type SenderChain []Sender

// Send tries each sender in order. It returns the first nil error, or the last
// error if all senders fail.
func (sc SenderChain) Send(ctx context.Context, address string, msg Message) error {
	var lastErr error
	for _, s := range sc {
		if err := s.Send(ctx, address, msg); err != nil {
			lastErr = err
			continue
		}
		return nil
	}
	return lastErr
}

// Sub-structs group related dependencies by role.
type input struct {
	Resolver
	Formatter
}

type output struct {
	Sender
}

// A Dispatcher resolves, formats, and sends notifications.
type Dispatcher struct {
	in  input
	out output
	log Logger
}

// DispatcherOption configures a Dispatcher.
type DispatcherOption func(*Dispatcher)

// WithLogger sets the logger. Defaults to NopLogger.
func WithLogger(l Logger) DispatcherOption {
	return func(d *Dispatcher) { d.log = l }
}

// WithFormatter sets the formatter. Defaults to a passthrough formatter.
func WithFormatter(f Formatter) DispatcherOption {
	return func(d *Dispatcher) { d.in.Formatter = f }
}

// NewDispatcher returns a new Dispatcher. The Resolver and Sender are required.
// Optional dependencies are configured via DispatcherOption.
func NewDispatcher(r Resolver, s Sender, o ...DispatcherOption) *Dispatcher {
	d := &Dispatcher{
		in: input{
			Resolver: r,
			Formatter: FormatterFn(func(n Notification) (Message, error) {
				return Message{Subject: n.Subject, Body: n.Body}, nil
			}),
		},
		out: output{Sender: s},
		log: NopLogger{},
	}
	for _, fn := range o {
		fn(d)
	}
	return d
}

// Dispatch resolves the user's address, formats the notification, and sends it.
// This is the single main method. No private methods — each step is a call to
// an injected dependency.
func (d *Dispatcher) Dispatch(ctx context.Context, n Notification) error {
	addr, err := d.in.Resolve(ctx, n.UserID)
	if err != nil {
		return fmt.Errorf("cannot resolve address for user %q: %w", n.UserID, err)
	}

	msg, err := d.in.Format(n)
	if err != nil {
		return fmt.Errorf("cannot format notification: %w", err)
	}

	d.log.Info("sending notification", "user", n.UserID, "address", addr)

	if err := d.out.Send(ctx, addr, msg); err != nil {
		return fmt.Errorf("cannot send notification: %w", err)
	}

	return nil
}
```

## `notify/logged/logged.go`

A decorator that wraps any `Sender` with structured logging. It lives in a child
package — it imports the parent's interface, the parent doesn't import it.

```go
// Package logged provides a logging decorator for notify.Sender.
package logged

import (
	"context"
	"fmt"

	"example.com/notify"
)

// A Sender wraps a notify.Sender with logging.
type Sender struct {
	wrapped notify.Sender
	log     notify.Logger
}

// NewSender returns a Sender that logs before and after sending.
func NewSender(s notify.Sender, l notify.Logger) *Sender {
	return &Sender{wrapped: s, log: l}
}

// Send logs the send attempt, delegates to the wrapped sender, and logs the
// outcome.
func (s *Sender) Send(ctx context.Context, address string, msg notify.Message) error {
	s.log.Info("sending", "address", address, "subject", msg.Subject)

	if err := s.wrapped.Send(ctx, address, msg); err != nil {
		s.log.Info("send failed", "address", address, "error", err)
		return fmt.Errorf("cannot send to %q: %w", address, err)
	}

	s.log.Info("sent", "address", address)
	return nil
}
```

## Wiring It Together

```go
log := slog.Default()

d := notify.NewDispatcher(
	ldap.NewResolver(ldapClient),
	notify.SenderChain{
		logged.NewSender(email.NewSender(smtpAddr), log),
		logged.NewSender(sms.NewSender(twilioClient), log),
	},
	notify.WithLogger(log),
	notify.WithFormatter(markdown.NewFormatter()),
)

err := d.Dispatch(ctx, notify.Notification{
	UserID:  "u-123",
	Subject: "Deployment complete",
	Body:    "v2.1.0 rolled out to production.",
})
```

## Patterns Demonstrated

| Pattern | Where |
|---|---|
| Small interfaces (1 method each) | `Resolver`, `Sender`, `Formatter` |
| `*Fn` adapters | `ResolverFn`, `SenderFn`, `FormatterFn` |
| Nop default | `NopLogger{}`, passthrough `FormatterFn` |
| Functional options | `WithLogger`, `WithFormatter` |
| Required vs optional deps | `Resolver`/`Sender` positional, rest optional |
| Sub-struct grouping | `input{Resolver, Formatter}`, `output{Sender}` |
| No private methods | `Dispatch` calls only injected deps |
| Chain type | `SenderChain` for fallback delivery |
| Decorator in child package | `logged.Sender` wraps `notify.Sender` |
| Error wrapping | `"cannot resolve address for user %q: %w"` |
| Accept interfaces, return structs | `NewDispatcher` takes interfaces, returns `*Dispatcher` |

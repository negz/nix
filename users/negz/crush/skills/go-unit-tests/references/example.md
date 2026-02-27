# Complete Example

A `UserStore` that wraps a database interface, its mock, and full test.

## Production Code (`store.go`)

```go
package user

import (
	"context"
	"fmt"
)

// A DB reads and writes user records.
type DB interface {
	Get(ctx context.Context, id string) (Record, error)
	Put(ctx context.Context, r Record) error
}

// A Record is a user record.
type Record struct {
	ID   string
	Name string
}

// A Store reads and writes users.
type Store struct {
	db DB
}

// NewStore returns a new Store.
func NewStore(db DB) *Store {
	return &Store{db: db}
}

// Rename changes a user's name. It returns the updated record.
func (s *Store) Rename(ctx context.Context, id, name string) (Record, error) {
	r, err := s.db.Get(ctx, id)
	if err != nil {
		return Record{}, fmt.Errorf("cannot get user: %w", err)
	}

	r.Name = name

	if err := s.db.Put(ctx, r); err != nil {
		return Record{}, fmt.Errorf("cannot put user: %w", err)
	}

	return r, nil
}
```

## Test Code (`store_test.go`)

```go
package user

import (
	"context"
	"errors"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
)

var errBoom = errors.New("boom")

// Compile-time interface check.
var _ DB = &MockDB{}

// MockDB is a mock implementation of DB.
type MockDB struct {
	MockGet func(ctx context.Context, id string) (Record, error)
	MockPut func(ctx context.Context, r Record) error
}

func (m *MockDB) Get(ctx context.Context, id string) (Record, error) {
	return m.MockGet(ctx, id)
}

func (m *MockDB) Put(ctx context.Context, r Record) error {
	return m.MockPut(ctx, r)
}

func NewMockGetFn(r Record, err error) func(context.Context, string) (Record, error) {
	return func(_ context.Context, _ string) (Record, error) { return r, err }
}

func NewMockPutFn(err error) func(context.Context, Record) error {
	return func(_ context.Context, _ Record) error { return err }
}

func TestRename(t *testing.T) {
	type params struct {
		db DB
	}
	type args struct {
		ctx  context.Context
		id   string
		name string
	}
	type want struct {
		r   Record
		err error
	}

	cases := map[string]struct {
		reason string
		params params
		args   args
		want   want
	}{
		"GetError": {
			reason: "We should return any error encountered getting the user.",
			params: params{
				db: &MockDB{
					MockGet: NewMockGetFn(Record{}, errBoom),
				},
			},
			args: args{
				ctx:  context.Background(),
				id:   "user-1",
				name: "newname",
			},
			want: want{
				err: cmpopts.AnyError,
			},
		},
		"PutError": {
			reason: "We should return any error encountered putting the user.",
			params: params{
				db: &MockDB{
					MockGet: NewMockGetFn(Record{ID: "user-1", Name: "old"}, nil),
					MockPut: NewMockPutFn(errBoom),
				},
			},
			args: args{
				ctx:  context.Background(),
				id:   "user-1",
				name: "newname",
			},
			want: want{
				err: cmpopts.AnyError,
			},
		},
		"Success": {
			reason: "We should return the updated record when the rename succeeds.",
			params: params{
				db: &MockDB{
					MockGet: NewMockGetFn(Record{ID: "user-1", Name: "old"}, nil),
					MockPut: NewMockPutFn(nil),
				},
			},
			args: args{
				ctx:  context.Background(),
				id:   "user-1",
				name: "newname",
			},
			want: want{
				r: Record{ID: "user-1", Name: "newname"},
			},
		},
	}

	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			s := NewStore(tc.params.db)
			got, err := s.Rename(tc.args.ctx, tc.args.id, tc.args.name)

			if diff := cmp.Diff(tc.want.err, err, cmpopts.EquateErrors()); diff != "" {
				t.Errorf("\n%s\nRename(...): -want error, +got error:\n%s", tc.reason, diff)
			}
			if diff := cmp.Diff(tc.want.r, got); diff != "" {
				t.Errorf("\n%s\nRename(...): -want, +got:\n%s", tc.reason, diff)
			}
		})
	}
}
```

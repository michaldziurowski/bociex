---
name: go-database
description: "Use when setting up database layer in Go projects. Enforces SQLite, sqlc, go:generate pattern, RFC3339 dates in UTC. Triggers: database setup, sqlc, sqlite, go database, data layer."
---

# Go Database Layer

Database layer conventions for Go applications using SQLite and sqlc.

**Applies only when the project does not already have a database setup.** If the project has an existing database layer, follow existing conventions instead.

## Technology Stack

| Component | Technology |
|-----------|------------|
| Database | SQLite |
| Query Generator | sqlc |
| Date Format | RFC3339 (TEXT), always UTC |

## sqlc as Go Tool

Declare sqlc as a tool dependency in `go.mod`:

```go
//go:build tools

package tools

import (
    _ "github.com/sqlc-dev/sqlc/cmd/sqlc"
)
```

Create `tools.go` in the project root with this content. Run `go mod tidy` to add the dependency.

## Code Generation

Place `//go:generate` directive in the db package:

```go
// internal/db/generate.go
package db

//go:generate go run github.com/sqlc-dev/sqlc/cmd/sqlc generate
```

Run `go generate ./...` to generate sqlc files.

## sqlc Configuration

```yaml
# sqlc.yaml
version: "2"
sql:
  - engine: "sqlite"
    queries: "internal/db/queries.sql"
    schema: "internal/db/schema.sql"
    gen:
      go:
        package: "db"
        out: "internal/db"
```

## Date Handling

Store dates as RFC3339 TEXT in SQLite, always in UTC.

### Schema

```sql
CREATE TABLE events (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL,  -- RFC3339 format
    updated_at TEXT NOT NULL   -- RFC3339 format
);
```

### Custom Time Type

sqlc needs a custom type to properly scan RFC3339 strings into `time.Time`:

```go
// internal/db/time.go
package db

import (
    "database/sql/driver"
    "fmt"
    "time"
)

// Time wraps time.Time for SQLite RFC3339 text storage.
type Time struct {
    time.Time
}

func (t *Time) Scan(value interface{}) error {
    if value == nil {
        t.Time = time.Time{}
        return nil
    }
    s, ok := value.(string)
    if !ok {
        return fmt.Errorf("expected string, got %T", value)
    }
    parsed, err := time.Parse(time.RFC3339, s)
    if err != nil {
        return err
    }
    t.Time = parsed
    return nil
}

func (t Time) Value() (driver.Value, error) {
    if t.IsZero() {
        return nil, nil
    }
    return t.UTC().Format(time.RFC3339), nil
}

func Now() Time {
    return Time{time.Now().UTC()}
}
```

### sqlc Override

Add type override in `sqlc.yaml`:

```yaml
version: "2"
sql:
  - engine: "sqlite"
    queries: "internal/db/queries.sql"
    schema: "internal/db/schema.sql"
    gen:
      go:
        package: "db"
        out: "internal/db"
        overrides:
          - column: "*.created_at"
            go_type: "Time"
          - column: "*.updated_at"
            go_type: "Time"
```

### Usage

```go
// Insert with UTC time
now := db.Now()
queries.CreateEvent(ctx, db.CreateEventParams{
    Name:      "Meeting",
    CreatedAt: now,
    UpdatedAt: now,
})

// Display in local timezone
event, _ := queries.GetEvent(ctx, id)
fmt.Println(event.CreatedAt.Local().Format("2006-01-02 15:04"))
```

## Directory Structure

```
internal/db/
├── generate.go      # //go:generate directive
├── migrate.go       # Migration runner
├── schema.sql       # Table definitions (full schema for sqlc)
├── queries.sql      # sqlc queries
├── time.go          # Custom Time type
├── migrations/      # SQL migration files
│   ├── 001_initial.sql
│   ├── 002_add_feature.sql
│   └── ...
├── db.go            # Generated
├── models.go        # Generated
└── queries.sql.go   # Generated
```

## Migrations

Embedded SQL migrations with a custom runner. No external tools required.

### Migration Files

Place SQL files in `internal/db/migrations/` with numeric prefixes:

```
migrations/
├── 001_initial.sql
├── 002_add_users.sql
└── 003_add_indexes.sql
```

### Migration Runner

```go
// internal/db/migrate.go
package db

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	"log/slog"
	"sort"
	"strings"
)

//go:embed migrations/*.sql
var migrationsFS embed.FS

func Migrate(ctx context.Context, db *sql.DB) error {
	if err := createMigrationsTable(ctx, db); err != nil {
		return err
	}
	applied, err := getAppliedMigrations(ctx, db)
	if err != nil {
		return err
	}
	pending, err := getPendingMigrations(applied)
	if err != nil {
		return err
	}
	for _, name := range pending {
		if err := runMigration(ctx, db, name); err != nil {
			return fmt.Errorf("migration %s: %w", name, err)
		}
		slog.Info("applied migration", "name", name)
	}
	return nil
}

func createMigrationsTable(ctx context.Context, db *sql.DB) error {
	_, err := db.ExecContext(ctx, `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version TEXT PRIMARY KEY,
			applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)
	`)
	return err
}

func getAppliedMigrations(ctx context.Context, db *sql.DB) (map[string]bool, error) {
	rows, err := db.QueryContext(ctx, "SELECT version FROM schema_migrations")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	applied := make(map[string]bool)
	for rows.Next() {
		var version string
		if err := rows.Scan(&version); err != nil {
			return nil, err
		}
		applied[version] = true
	}
	return applied, rows.Err()
}

func getPendingMigrations(applied map[string]bool) ([]string, error) {
	entries, err := migrationsFS.ReadDir("migrations")
	if err != nil {
		return nil, err
	}
	var pending []string
	for _, e := range entries {
		if !e.IsDir() && strings.HasSuffix(e.Name(), ".sql") && !applied[e.Name()] {
			pending = append(pending, e.Name())
		}
	}
	sort.Strings(pending)
	return pending, nil
}

func runMigration(ctx context.Context, db *sql.DB, name string) error {
	content, err := migrationsFS.ReadFile("migrations/" + name)
	if err != nil {
		return err
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.ExecContext(ctx, string(content)); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, "INSERT INTO schema_migrations (version) VALUES (?)", name); err != nil {
		return err
	}
	return tx.Commit()
}
```

### Call on Startup

```go
// cmd/server/main.go
func main() {
	db, err := sql.Open("sqlite", "data/app.db")
	if err != nil {
		slog.Error("db open failed", "err", err)
		os.Exit(1)
	}
	if err := db.Migrate(context.Background(), db); err != nil {
		slog.Error("migration failed", "err", err)
		os.Exit(1)
	}
	// ... rest of startup
}
```

### schema.sql for sqlc

Keep `schema.sql` as the full schema (all tables with `IF NOT EXISTS`). sqlc uses this for code generation while migrations handle actual DB changes.

## Quality Checklist

- [ ] sqlc declared as Go tool in `tools.go`
- [ ] `//go:generate` directive in db package
- [ ] Dates stored as RFC3339 TEXT
- [ ] All timestamps in UTC
- [ ] Custom Time type for scanning
- [ ] Type overrides in sqlc.yaml for date columns
- [ ] Migrations in `internal/db/migrations/` with numeric prefixes
- [ ] Migration runner with `//go:embed migrations/*.sql`
- [ ] Migrations called on startup (fail-fast)

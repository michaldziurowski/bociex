# Alpine AJAX Patterns

Alpine AJAX enables server-driven partial page updates. The server returns HTML fragments that replace targeted elements.

## Setup

Include Alpine.js and the AJAX plugin:

```html
<script src="/static/js/alpine.min.js" defer></script>
<script src="/static/js/ajax.min.js" defer></script>
```

Download from: https://alpine-ajax.js.org/

## Core Concepts

### x-target Attribute

`x-target` specifies which element receives the server response:

```html
<form x-init x-target="results" action="/search">
    <input type="search" name="q"/>
    <button>Search</button>
</form>

<div id="results">
    <!-- Server response replaces this content -->
</div>
```

### Target Modifiers

| Modifier | Behavior |
|----------|----------|
| `x-target="id"` | Replace inner content of target |
| `x-target.replace="id"` | Replace entire element |
| `x-target.append="id"` | Append response to target |
| `x-target.prepend="id"` | Prepend response to target |

## Form Patterns

### Basic Form Submission

Forms with `x-target` submit via AJAX automatically:

```html
<form x-init x-target="messages" action="/messages" method="post">
    <input name="content" required/>
    <button>Send</button>
</form>

<ul id="messages">
    <!-- New messages appear here -->
</ul>
```

### Form with Reset on Success

```html
<form
    x-init
    x-target="items"
    action="/items"
    method="post"
    @ajax:success="$el.reset()"
>
    <input name="title" required/>
    <button>Add Item</button>
</form>
```

### Search with Debounce

```html
<form x-init x-target="results" action="/search">
    <input
        type="search"
        name="q"
        @input.debounce.300ms="$el.form.requestSubmit()"
    />
</form>

<div id="results"></div>
```

## Link Patterns

### AJAX Link

```html
<a x-init x-target="content" href="/page/2">Next Page</a>

<div id="content">
    <!-- Page content loaded here -->
</div>
```

### Navigation with Active State

Handle via server - return updated nav with active class:

```go
templ NavLink(href string, label string, current string) {
    <a
        x-init
        x-target="main-content"
        href={ templ.SafeURL(href) }
        class={ templ.KV("active", href == current) }
    >
        { label }
    </a>
}
```

## Loading States

### Disable During Request

```html
<form x-init x-target="results" action="/search">
    <button x-bind:disabled="$ajax.submitting">
        <span x-show="!$ajax.submitting">Search</span>
        <span x-show="$ajax.submitting">Loading...</span>
    </button>
</form>
```

### Loading Indicator

```html
<div x-data>
    <form x-init x-target="results" action="/data">
        <button>Load Data</button>
    </form>

    <div id="results">
        <template x-if="$ajax.loading">
            <div class="loading">Loading...</div>
        </template>
    </div>
</div>
```

## Event Handling

### Available Events

| Event | When |
|-------|------|
| `ajax:before` | Before request is sent |
| `ajax:success` | Request completed successfully |
| `ajax:error` | Request failed |
| `ajax:after` | After request completes (success or error) |

### Example Usage

```html
<form
    x-init
    x-target="results"
    action="/submit"
    method="post"
    @ajax:success="showNotification('Saved!')"
    @ajax:error="showNotification('Error occurred')"
>
    ...
</form>
```

## Server Response Patterns

### Return Partial HTML

Handler returns just the fragment to update:

```go
func handleSearch(w http.ResponseWriter, r *http.Request) {
    query := r.URL.Query().Get("q")
    results := search(query)

    // Return just the results list, not full page
    templates.SearchResults(results).Render(r.Context(), w)
}
```

```go
templ SearchResults(results []Result) {
    if len(results) == 0 {
        <p>No results found.</p>
    } else {
        <ul>
            for _, r := range results {
                <li>{ r.Title }</li>
            }
        </ul>
    }
}
```

### Multiple Targets

Server can return multiple elements; Alpine AJAX matches by ID:

```go
templ UpdateResponse(user User, stats Stats) {
    <div id="user-info">
        @UserCard(user)
    </div>
    <div id="stats">
        @StatsPanel(stats)
    </div>
}
```

```html
<button x-init x-target="user-info stats" hx-get="/refresh">
    Refresh
</button>
```

## Server State vs Client State

Prefer server state. Use Alpine.js client state only for:

- UI-only concerns (dropdowns, modals open/close)
- Optimistic updates
- Form validation feedback

Everything else should come from the server.

### Client State Example

```html
<div x-data="{ open: false }">
    <button @click="open = !open">Menu</button>
    <nav x-show="open" @click.outside="open = false">
        <a href="/settings">Settings</a>
        <a href="/logout">Logout</a>
    </nav>
</div>
```

### Server State Example

User data, lists, counts - fetch from server:

```html
<div id="notifications">
    @NotificationList(notifications)
</div>

<button x-init x-target="notifications" hx-get="/notifications">
    Refresh
</button>
```

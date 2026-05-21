# NotesAppPlus

A lightweight, native macOS notes app. Two-pane split view, plain Markdown files on disk, SQLite for metadata and full-text search. No web views, no Electron, no large dependencies.

---

## Architecture

```
App/
  AppDelegate.swift          – Creates the object graph and main window.
  MainWindowController.swift – Owns the NSWindow, sets up the window style.

UI/
  RootSplitViewController.swift   – NSSplitViewController; coordinator between list and editor.
  NotesListViewController.swift   – Left pane: search field, new/delete buttons, NSTableView.
  EditorViewController.swift      – Right pane: NSTextView with debounced autosave.

Models/
  Note.swift                 – Plain struct. Static helpers for title/preview extraction.

Storage/
  SQLiteDatabase.swift       – Thin wrapper around the system sqlite3 C library.
  NoteRepository.swift       – CRUD against the `notes` table.
  FileStore.swift            – Read/write `.md` files in Application Support.
  SearchIndex.swift          – FTS5 index: insert, delete, prefix search.

Services/
  AutosaveService.swift      – DispatchWorkItem-based debounce (~500 ms).

Utilities/
  Paths.swift                – Centralised URLs for the database and notes directory.
  DateFormatting.swift       – ISO 8601 for storage; relative/absolute display strings.
```

### Data flow

1. User types in `EditorViewController`.
2. `AutosaveService` debounces. After ~500 ms it calls `performSave`.
3. `performSave` writes the Markdown file, updates the SQLite row, refreshes the FTS5 index.
4. It notifies `RootSplitViewController` via `EditorDelegate`.
5. `RootSplitViewController` calls `listVC.noteWasUpdated(_:)` so the list cell refreshes.

---

## How notes are stored

| Artefact | Location (sandboxed) |
|---|---|
| Markdown files | `~/Library/Containers/…/Data/Library/Application Support/NotesAppPlus/Notes/<uuid>.md` |
| SQLite database | `~/Library/Containers/…/Data/Library/Application Support/NotesAppPlus/notes.sqlite` |

`FileManager.urls(for: .applicationSupportDirectory, …)` resolves to the container path automatically in sandboxed apps. No hardcoded paths.

SQLite schema:

```sql
CREATE TABLE notes (
    id         TEXT PRIMARY KEY,
    title      TEXT NOT NULL,
    path       TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    preview    TEXT NOT NULL,
    pinned     INTEGER NOT NULL DEFAULT 0
);

CREATE VIRTUAL TABLE notes_fts
USING fts5(id UNINDEXED, title, body);
```

Only metadata is loaded at startup. Note bodies are read from disk on selection.

---

## How search works

Search is backed by SQLite FTS5. Each save call calls `SearchIndex.upsert(id:title:body:)` which deletes the old FTS row and inserts the new one. The query is split into whitespace-separated tokens; each token is matched as a prefix (`token*`). Results are returned by FTS5 rank and then filtered against the in-memory metadata list. An empty query shows all notes sorted by `updated_at DESC`.

---

## How to build and run

Requirements: Xcode 26+ (macOS 26 SDK).

1. Open `NotesAppPlus.xcodeproj` in Xcode.
2. Select the **NotesAppPlus** scheme.
3. Press **⌘R** to build and run.

To run tests: **⌘U** or select the **NotesAppPlusTests** scheme.

There are no third-party dependencies. SQLite3 is linked via `-lsqlite3` (system library).

---

## What is intentionally not included

- iCloud / CloudKit sync
- Markdown preview rendering
- Rich text or formatting toolbar
- Attachments, images, file embeds
- AI features
- Tags or folders
- Themes / custom fonts
- Menu bar mode
- Collaboration / sharing
- Login or authentication
- Analytics or crash reporting SDKs
- Web views of any kind

---

## Future ideas (not on the roadmap)

- Markdown preview pane (using a `WKWebView` or custom renderer)
- Pinned notes UI (the `pinned` column is already in the schema)
- Quick Open palette (fuzzy search by title, `⌘K` shortcut)
- Export to PDF or HTML
- iCloud Drive sync (flat file approach — no Core Data required)
- Tag support (separate `tags` table + junction table)
- Dark/light mode accent colour picker
- Keyboard shortcut to focus the search field
- Word count in the status bar

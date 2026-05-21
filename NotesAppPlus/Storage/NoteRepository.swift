import Foundation
import SQLite3

final class NoteRepository {
    private let db: SQLiteDatabase

    init(database: SQLiteDatabase) {
        self.db = database
        createSchemaIfNeeded()
    }

    private func createSchemaIfNeeded() {
        let notesTable = """
            CREATE TABLE IF NOT EXISTS notes (
                id         TEXT PRIMARY KEY,
                title      TEXT NOT NULL,
                path       TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                preview    TEXT NOT NULL,
                pinned     INTEGER NOT NULL DEFAULT 0
            )
            """
        let ftsTable = """
            CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts
            USING fts5(id UNINDEXED, title, body)
            """
        try? db.execute(notesTable)
        try? db.execute(ftsTable)
    }

    // MARK: - Queries

    func allNotes() -> [Note] {
        let sql = """
            SELECT id, title, path, created_at, updated_at, preview, pinned
            FROM notes
            ORDER BY pinned DESC, updated_at DESC
            """
        guard let stmt = try? db.prepare(sql) else { return [] }
        defer { sqlite3_finalize(stmt) }
        return collectNotes(from: stmt)
    }

    // MARK: - Mutations

    func insert(_ note: Note) throws {
        let sql = """
            INSERT INTO notes (id, title, path, created_at, updated_at, preview, pinned)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """
        let stmt = try db.prepare(sql)
        defer { sqlite3_finalize(stmt) }

        bindText(stmt, 1, note.id)
        bindText(stmt, 2, note.title)
        bindText(stmt, 3, note.path)
        bindText(stmt, 4, ISO8601Format.string(from: note.createdAt))
        bindText(stmt, 5, ISO8601Format.string(from: note.updatedAt))
        bindText(stmt, 6, note.preview)
        sqlite3_bind_int(stmt, 7, note.pinned ? 1 : 0)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SQLiteDatabase.DBError.stepFailed(db.lastErrorMessage)
        }
    }

    func update(_ note: Note) throws {
        let sql = """
            UPDATE notes
            SET title = ?, updated_at = ?, preview = ?, pinned = ?
            WHERE id = ?
            """
        let stmt = try db.prepare(sql)
        defer { sqlite3_finalize(stmt) }

        bindText(stmt, 1, note.title)
        bindText(stmt, 2, ISO8601Format.string(from: note.updatedAt))
        bindText(stmt, 3, note.preview)
        sqlite3_bind_int(stmt, 4, note.pinned ? 1 : 0)
        bindText(stmt, 5, note.id)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SQLiteDatabase.DBError.stepFailed(db.lastErrorMessage)
        }
    }

    func delete(id: String) throws {
        let sql = "DELETE FROM notes WHERE id = ?"
        let stmt = try db.prepare(sql)
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, id)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SQLiteDatabase.DBError.stepFailed(db.lastErrorMessage)
        }
    }

    // MARK: - Helpers

    private func collectNotes(from stmt: OpaquePointer) -> [Note] {
        var results: [Note] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard
                let idPtr      = sqlite3_column_text(stmt, 0),
                let titlePtr   = sqlite3_column_text(stmt, 1),
                let pathPtr    = sqlite3_column_text(stmt, 2),
                let createdPtr = sqlite3_column_text(stmt, 3),
                let updatedPtr = sqlite3_column_text(stmt, 4),
                let previewPtr = sqlite3_column_text(stmt, 5)
            else { continue }

            let createdStr = String(cString: createdPtr)
            let updatedStr = String(cString: updatedPtr)
            guard
                let createdAt = ISO8601Format.date(from: createdStr),
                let updatedAt = ISO8601Format.date(from: updatedStr)
            else { continue }

            results.append(Note(
                id: String(cString: idPtr),
                title: String(cString: titlePtr),
                path: String(cString: pathPtr),
                createdAt: createdAt,
                updatedAt: updatedAt,
                preview: String(cString: previewPtr),
                pinned: sqlite3_column_int(stmt, 6) != 0
            ))
        }
        return results
    }

    private func bindText(_ stmt: OpaquePointer, _ index: Int32, _ value: String) {
        sqlite3_bind_text(stmt, index, value, -1, sqliteTransient)
    }
}

import Foundation
import SQLite3

final class SearchIndex {
    private let db: SQLiteDatabase

    init(database: SQLiteDatabase) {
        self.db = database
    }

    func upsert(id: String, title: String, body: String) {
        // FTS5 virtual tables don't support INSERT OR REPLACE; delete first.
        delete(id: id)
        guard let stmt = try? db.prepare(
            "INSERT INTO notes_fts (id, title, body) VALUES (?, ?, ?)"
        ) else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, id,    -1, sqliteTransient)
        sqlite3_bind_text(stmt, 2, title, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 3, body,  -1, sqliteTransient)
        sqlite3_step(stmt)
    }

    func delete(id: String) {
        guard let stmt = try? db.prepare("DELETE FROM notes_fts WHERE id = ?") else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, id, -1, sqliteTransient)
        sqlite3_step(stmt)
    }

    // Returns IDs of matching notes. Each search term is matched as a prefix.
    func search(query: String) -> [String] {
        let terms = query.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .compactMap { word -> String? in
                let safe = word.filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
                return safe.isEmpty ? nil : "\(safe)*"
            }
            .joined(separator: " ")

        guard !terms.isEmpty else { return [] }

        guard let stmt = try? db.prepare(
            "SELECT id FROM notes_fts WHERE notes_fts MATCH ? ORDER BY rank"
        ) else { return [] }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, terms, -1, sqliteTransient)

        var ids: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let ptr = sqlite3_column_text(stmt, 0) {
                ids.append(String(cString: ptr))
            }
        }
        return ids
    }
}

import Foundation
import SQLite3

// SQLITE_TRANSIENT is a C macro; reproduce it here.
let sqliteTransient = unsafeBitCast(-1 as Int, to: sqlite3_destructor_type.self)

final class SQLiteDatabase {
    private let db: OpaquePointer

    private init(db: OpaquePointer) {
        self.db = db
    }

    deinit {
        sqlite3_close(db)
    }

    static func open(at url: URL) throws -> SQLiteDatabase {
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        var handle: OpaquePointer?
        guard sqlite3_open(url.path, &handle) == SQLITE_OK, let handle else {
            throw DBError.cannotOpen(url.path)
        }
        let database = SQLiteDatabase(db: handle)
        try database.configure()
        return database
    }

    private func configure() throws {
        try execute("PRAGMA journal_mode = WAL")
        try execute("PRAGMA synchronous = NORMAL")
        try execute("PRAGMA foreign_keys = ON")
    }

    func execute(_ sql: String) throws {
        var errmsg: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errmsg) == SQLITE_OK else {
            let msg = errmsg.map { String(cString: $0) } ?? "unknown error"
            sqlite3_free(errmsg)
            throw DBError.executionFailed(msg)
        }
    }

    func prepare(_ sql: String) throws -> OpaquePointer {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        return stmt
    }

    var lastErrorMessage: String { String(cString: sqlite3_errmsg(db)) }

    enum DBError: Error, LocalizedError {
        case cannotOpen(String)
        case executionFailed(String)
        case prepareFailed(String)
        case stepFailed(String)

        var errorDescription: String? {
            switch self {
            case .cannotOpen(let p): return "Cannot open database at \(p)"
            case .executionFailed(let m): return "SQL execution failed: \(m)"
            case .prepareFailed(let m): return "SQL prepare failed: \(m)"
            case .stepFailed(let m): return "SQL step failed: \(m)"
            }
        }
    }
}

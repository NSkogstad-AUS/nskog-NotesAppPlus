import Foundation

final class FileStore {
    private let directory: URL

    init(notesDirectory: URL) {
        self.directory = notesDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func write(body: String, to filename: String) throws {
        try body.write(to: url(for: filename), atomically: true, encoding: .utf8)
    }

    func read(filename: String) throws -> String {
        try String(contentsOf: url(for: filename), encoding: .utf8)
    }

    func delete(filename: String) throws {
        try FileManager.default.removeItem(at: url(for: filename))
    }

    func filename(for id: String) -> String { "\(id).md" }

    private func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }
}

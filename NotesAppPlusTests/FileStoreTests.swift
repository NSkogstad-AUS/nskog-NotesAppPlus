import XCTest
@testable import NotesAppPlus

final class FileStoreTests: XCTestCase {
    private var store: FileStore!
    private var tempDir: URL!

    override func setUp() {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        store = FileStore(notesDirectory: tempDir)
    }

    override func tearDown() throws {
        try FileManager.default.removeItem(at: tempDir)
    }

    func testWriteAndReadRoundTrip() throws {
        let filename = "test.md"
        let body     = "# Hello\n\nThis is a note."
        try store.write(body: body, to: filename)
        let read = try store.read(filename: filename)
        XCTAssertEqual(read, body)
    }

    func testDeleteRemovesFile() throws {
        let filename = "delete-me.md"
        try store.write(body: "content", to: filename)
        try store.delete(filename: filename)
        XCTAssertThrowsError(try store.read(filename: filename))
    }

    func testFilenameForIDHasMdExtension() {
        let id       = UUID().uuidString
        let filename = store.filename(for: id)
        XCTAssertTrue(filename.hasSuffix(".md"))
        XCTAssertTrue(filename.hasPrefix(id))
    }

    func testWriteCreatesDirectoryIfMissing() throws {
        let nested = tempDir.appendingPathComponent("nested/dir")
        let nestedStore = FileStore(notesDirectory: nested)
        try nestedStore.write(body: "hello", to: "note.md")
        let read = try nestedStore.read(filename: "note.md")
        XCTAssertEqual(read, "hello")
    }

    func testOverwriteUpdatesContent() throws {
        let filename = "overwrite.md"
        try store.write(body: "original", to: filename)
        try store.write(body: "updated", to: filename)
        let read = try store.read(filename: filename)
        XCTAssertEqual(read, "updated")
    }
}

import XCTest
@testable import NotesAppPlus

final class NoteRepositoryTests: XCTestCase {
    private var db: SQLiteDatabase!
    private var repo: NoteRepository!
    private var searchIndex: SearchIndex!
    private var tempDir: URL!

    override func setUp() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        db          = try SQLiteDatabase.open(at: tempDir.appendingPathComponent("test.sqlite"))
        repo        = NoteRepository(database: db)
        searchIndex = SearchIndex(database: db)
    }

    override func tearDown() throws {
        db   = nil
        repo = nil
        try FileManager.default.removeItem(at: tempDir)
    }

    func testInsertAndFetch() throws {
        let note = makeNote(title: "Hello World")
        try repo.insert(note)

        let all = repo.allNotes()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].title, "Hello World")
    }

    func testUpdateChangesTitle() throws {
        var note = makeNote(title: "Original")
        try repo.insert(note)

        note.title     = "Updated"
        note.updatedAt = Date()
        try repo.update(note)

        let all = repo.allNotes()
        XCTAssertEqual(all[0].title, "Updated")
    }

    func testDeleteRemovesNote() throws {
        let note = makeNote(title: "To Delete")
        try repo.insert(note)
        try repo.delete(id: note.id)

        XCTAssertTrue(repo.allNotes().isEmpty)
    }

    func testMultipleNotesSortedByUpdatedAt() throws {
        let older = makeNote(title: "Older", updatedAt: Date(timeIntervalSinceNow: -3600))
        let newer = makeNote(title: "Newer", updatedAt: Date())
        try repo.insert(older)
        try repo.insert(newer)

        let all = repo.allNotes()
        XCTAssertEqual(all.first?.title, "Newer")
    }

    func testSearchFindsInsertedNote() throws {
        let note = makeNote(title: "Swift Testing")
        try repo.insert(note)
        searchIndex.upsert(id: note.id, title: note.title, body: "This note is about testing in Swift")

        let results = searchIndex.search(query: "Swift")
        XCTAssertTrue(results.contains(note.id))
    }

    func testSearchDeleteRemovesFromIndex() throws {
        let note = makeNote(title: "Ephemeral Note")
        try repo.insert(note)
        searchIndex.upsert(id: note.id, title: note.title, body: "Some content")
        searchIndex.delete(id: note.id)

        let results = searchIndex.search(query: "Ephemeral")
        XCTAssertFalse(results.contains(note.id))
    }

    // MARK: - Title extraction

    func testTitleFromMarkdownHeader() {
        XCTAssertEqual(Note.extractTitle(from: "# My Title\nBody text"), "My Title")
    }

    func testTitleFromPlainFirstLine() {
        XCTAssertEqual(Note.extractTitle(from: "My Title\nBody text"), "My Title")
    }

    func testTitleFromEmptyBodyIsUntitled() {
        XCTAssertEqual(Note.extractTitle(from: ""), "Untitled")
    }

    func testTitleIgnoresLeadingBlankLines() {
        XCTAssertEqual(Note.extractTitle(from: "\n\nActual Title\n"), "Actual Title")
    }

    func testPreviewSkipsTitleLine() {
        let body = "Title Line\nThis is the preview content"
        XCTAssertEqual(Note.extractPreview(from: body), "This is the preview content")
    }

    func testPreviewTruncatesAt200() {
        let body = "Title\n" + String(repeating: "a", count: 300)
        XCTAssertEqual(Note.extractPreview(from: body).count, 200)
    }

    // MARK: - Helpers

    private func makeNote(
        title: String = "Test Note",
        updatedAt: Date = Date()
    ) -> Note {
        Note(
            id: UUID().uuidString,
            title: title,
            path: "\(UUID().uuidString).md",
            createdAt: Date(),
            updatedAt: updatedAt,
            preview: "",
            pinned: false
        )
    }
}

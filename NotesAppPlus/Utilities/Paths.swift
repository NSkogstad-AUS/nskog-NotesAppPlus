import Foundation

enum Paths {
    // In a sandboxed app this resolves to the app's container automatically.
    static var applicationSupportURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NotesAppPlus")
    }

    static var notesDirectoryURL: URL {
        applicationSupportURL.appendingPathComponent("Notes")
    }

    static var databaseURL: URL {
        applicationSupportURL.appendingPathComponent("notes.sqlite")
    }
}

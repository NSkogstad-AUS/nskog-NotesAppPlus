import AppKit

// Entry point is main.swift; this class must NOT carry @main.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let db          = try SQLiteDatabase.open(at: Paths.databaseURL)
            let repository  = NoteRepository(database: db)
            let fileStore   = FileStore(notesDirectory: Paths.notesDirectoryURL)
            let searchIndex = SearchIndex(database: db)

            windowController = MainWindowController(
                repository: repository,
                fileStore: fileStore,
                searchIndex: searchIndex
            )
            windowController?.showWindow(nil)
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {}

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}

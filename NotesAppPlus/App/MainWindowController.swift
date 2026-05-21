import AppKit

final class MainWindowController: NSWindowController {
    init(repository: NoteRepository, fileStore: FileStore, searchIndex: SearchIndex) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Notes"
        window.setFrameAutosaveName("MainWindow")
        window.minSize = NSSize(width: 640, height: 400)
        window.titlebarAppearsTransparent = false
        window.toolbarStyle = .unified

        super.init(window: window)

        let rootVC = RootSplitViewController(
            repository: repository,
            fileStore: fileStore,
            searchIndex: searchIndex
        )
        window.contentViewController = rootVC
        window.center()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }
}

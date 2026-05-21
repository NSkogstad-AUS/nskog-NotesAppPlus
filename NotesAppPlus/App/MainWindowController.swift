import AppKit

final class MainWindowController: NSWindowController {
    init(repository: NoteRepository, fileStore: FileStore, searchIndex: SearchIndex) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.setFrameAutosaveName("MainWindow")
        window.minSize = NSSize(width: 800, height: 500)

        // Unified toolbar makes the titlebar area merge with our content
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.showsBaselineSeparator = false
        window.toolbar = toolbar
        window.toolbarStyle = .unifiedCompact

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

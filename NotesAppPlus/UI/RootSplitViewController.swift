import AppKit

final class RootSplitViewController: NSSplitViewController {
    private let sidebarVC: SidebarViewController
    private let listVC: NotesListViewController
    private let editorVC: EditorViewController

    init(repository: NoteRepository, fileStore: FileStore, searchIndex: SearchIndex) {
        self.sidebarVC = SidebarViewController()
        self.listVC    = NotesListViewController(repository: repository,
                                                  fileStore: fileStore,
                                                  searchIndex: searchIndex)
        self.editorVC  = EditorViewController(repository: repository,
                                               fileStore: fileStore,
                                               searchIndex: searchIndex)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()

        splitView.isVertical   = true
        splitView.dividerStyle = .thin

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarVC)
        sidebarItem.minimumThickness = 200
        sidebarItem.maximumThickness = 280
        sidebarItem.collapseBehavior = .preferResizingSiblingsWithFixedSplitView

        let listItem = NSSplitViewItem(viewController: listVC)
        listItem.minimumThickness = 240
        listItem.maximumThickness = 420

        let editorItem = NSSplitViewItem(viewController: editorVC)
        editorItem.minimumThickness = 320

        addSplitViewItem(sidebarItem)
        addSplitViewItem(listItem)
        addSplitViewItem(editorItem)

        listVC.delegate   = self
        editorVC.delegate = self
    }
}

extension RootSplitViewController: NotesListDelegate {
    func didSelectNote(_ note: Note?) { editorVC.loadNote(note) }
}

extension RootSplitViewController: EditorDelegate {
    func editorDidSaveNote(_ note: Note) { listVC.noteWasUpdated(note) }
}

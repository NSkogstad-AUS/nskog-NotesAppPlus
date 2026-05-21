import AppKit

// Coordinator between the list pane and editor pane.
final class RootSplitViewController: NSSplitViewController {
    private let listVC: NotesListViewController
    private let editorVC: EditorViewController

    init(repository: NoteRepository, fileStore: FileStore, searchIndex: SearchIndex) {
        self.listVC   = NotesListViewController(repository: repository,
                                                fileStore: fileStore,
                                                searchIndex: searchIndex)
        self.editorVC = EditorViewController(repository: repository,
                                             fileStore: fileStore,
                                             searchIndex: searchIndex)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()

        splitView.isVertical = true
        splitView.dividerStyle = .thin

        let listItem = NSSplitViewItem(viewController: listVC)
        listItem.minimumThickness = 200
        listItem.maximumThickness = 380
        listItem.preferredThicknessFraction = 0.28

        let editorItem = NSSplitViewItem(viewController: editorVC)
        editorItem.minimumThickness = 320

        addSplitViewItem(listItem)
        addSplitViewItem(editorItem)

        listVC.delegate   = self
        editorVC.delegate = self
    }
}

extension RootSplitViewController: NotesListDelegate {
    func didSelectNote(_ note: Note?) {
        editorVC.loadNote(note)
    }
}

extension RootSplitViewController: EditorDelegate {
    func editorDidSaveNote(_ note: Note) {
        listVC.noteWasUpdated(note)
    }
}

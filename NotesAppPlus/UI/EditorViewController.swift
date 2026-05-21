import AppKit
import Foundation

protocol EditorDelegate: AnyObject {
    func editorDidSaveNote(_ note: Note)
}

final class EditorViewController: NSViewController {
    weak var delegate: EditorDelegate?

    private let repository: NoteRepository
    private let fileStore: FileStore
    private let searchIndex: SearchIndex
    private let autosave = AutosaveService(delay: 0.5)

    private var currentNote: Note?

    private let scrollView = NSScrollView()
    private let textView: NSTextView = {
        let tv = NSTextView()
        tv.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        tv.isEditable = true
        tv.isRichText = false
        tv.allowsUndo = true
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isGrammarCheckingEnabled = false
        tv.isContinuousSpellCheckingEnabled = false
        tv.textContainerInset = NSSize(width: 40, height: 24)
        tv.isHorizontallyResizable = false
        tv.isVerticallyResizable = true
        tv.autoresizingMask = [.width]
        tv.textContainer?.widthTracksTextView = true
        return tv
    }()
    private let emptyLabel: NSTextField = {
        let l = NSTextField(labelWithString: "Select a note, or create one.")
        l.textColor = .placeholderTextColor
        l.font = .systemFont(ofSize: 15)
        l.alignment = .center
        return l
    }()

    init(repository: NoteRepository, fileStore: FileStore, searchIndex: SearchIndex) {
        self.repository = repository
        self.fileStore = fileStore
        self.searchIndex = searchIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func loadView() { view = NSView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupEmptyLabel()
        showEmptyState(true)
    }

    private func setupScrollView() {
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        textView.delegate = self

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupEmptyLabel() {
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func showEmptyState(_ empty: Bool) {
        scrollView.isHidden = empty
        emptyLabel.isHidden = !empty
        textView.isEditable = !empty
    }

    // Called by RootSplitViewController when selection changes.
    func loadNote(_ note: Note?) {
        // Flush any pending save for the outgoing note before switching.
        if let outgoing = currentNote {
            autosave.cancelPending()
            performSave(note: outgoing, body: textView.string)
        }

        currentNote = note

        guard let note else {
            showEmptyState(true)
            textView.string = ""
            return
        }

        showEmptyState(false)
        do {
            textView.string = try fileStore.read(filename: note.path)
        } catch {
            textView.string = ""
        }
        textView.scrollToBeginningOfDocument(nil)
    }

    // MARK: - Save

    private func performSave(note: Note, body: String) {
        let title   = Note.extractTitle(from: body)
        let preview = Note.extractPreview(from: body)
        let now     = Date()

        var updated = note
        updated.title     = title
        updated.preview   = preview
        updated.updatedAt = now

        do {
            try fileStore.write(body: body, to: note.path)
            try repository.update(updated)
            searchIndex.upsert(id: note.id, title: title, body: body)
            delegate?.editorDidSaveNote(updated)
        } catch {
            // Autosave failures are non-fatal; they will retry on next keystroke.
        }
    }
}

extension EditorViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        guard let note = currentNote else { return }
        autosave.schedule { [weak self] in
            guard let self else { return }
            self.performSave(note: note, body: self.textView.string)
        }
    }
}

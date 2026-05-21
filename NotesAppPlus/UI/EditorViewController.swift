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

    // MARK: - Subviews

    private let scrollView = NSScrollView()
    private let textView: NSTextView = {
        let tv = NSTextView()
        tv.font = .systemFont(ofSize: 14)
        tv.isEditable = true
        tv.isRichText = false
        tv.allowsUndo = true
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled  = false
        tv.isGrammarCheckingEnabled             = false
        tv.isContinuousSpellCheckingEnabled     = false
        tv.textContainerInset = NSSize(width: 60, height: 24)
        tv.isHorizontallyResizable = false
        tv.isVerticallyResizable   = true
        tv.autoresizingMask        = [.width]
        tv.textContainer?.widthTracksTextView = true
        return tv
    }()

    // Timestamp shown above the body when a note is open
    private let timestampLabel: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.font = .systemFont(ofSize: 12)
        l.textColor = .tertiaryLabelColor
        l.alignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let emptyLabel: NSTextField = {
        let l = NSTextField(labelWithString: "Select a note, or create one.")
        l.textColor = .placeholderTextColor
        l.font = .systemFont(ofSize: 15)
        l.alignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    init(repository: NoteRepository, fileStore: FileStore, searchIndex: SearchIndex) {
        self.repository  = repository
        self.fileStore   = fileStore
        self.searchIndex = searchIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Lifecycle

    override func loadView() {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.white.cgColor
        view = v
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupTimestamp()
        setupEmptyLabel()
        showEmptyState(true)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        // Keep view background white even on appearance changes
        view.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
    }

    // MARK: - Setup

    private func setupScrollView() {
        scrollView.documentView      = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers  = true
        scrollView.borderType          = .noBorder
        scrollView.drawsBackground     = false
        textView.delegate              = self

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupTimestamp() {
        view.addSubview(timestampLabel)
        NSLayoutConstraint.activate([
            timestampLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            timestampLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func setupEmptyLabel() {
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func showEmptyState(_ empty: Bool) {
        scrollView.isHidden    = empty
        timestampLabel.isHidden = empty
        emptyLabel.isHidden    = !empty
        textView.isEditable    = !empty
    }

    // MARK: - Public API

    func loadNote(_ note: Note?) {
        if let outgoing = currentNote {
            autosave.cancelPending()
            performSave(note: outgoing, body: textView.string)
        }
        currentNote = note

        guard let note else { showEmptyState(true); textView.string = ""; return }

        showEmptyState(false)
        updateTimestamp(note.updatedAt)

        do {
            textView.string = try fileStore.read(filename: note.path)
        } catch {
            textView.string = ""
        }
        // Push text to top
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
            updateTimestamp(now)
            delegate?.editorDidSaveNote(updated)
        } catch {}
    }

    private func updateTimestamp(_ date: Date) {
        let fmt = DateFormatter()
        fmt.dateStyle = .long
        fmt.timeStyle = .short
        timestampLabel.stringValue = fmt.string(from: date)
    }
}

// MARK: - NSTextViewDelegate

extension EditorViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        guard let note = currentNote else { return }
        autosave.schedule { [weak self] in
            guard let self else { return }
            self.performSave(note: note, body: self.textView.string)
        }
    }
}

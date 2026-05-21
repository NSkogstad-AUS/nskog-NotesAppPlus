import AppKit
import Foundation

protocol NotesListDelegate: AnyObject {
    func didSelectNote(_ note: Note?)
}

final class NotesListViewController: NSViewController {
    weak var delegate: NotesListDelegate?

    private let repository: NoteRepository
    private let fileStore: FileStore
    private let searchIndex: SearchIndex

    private var allNotes: [Note] = []
    private var displayedNotes: [Note] = []

    // MARK: - Subviews

    private let searchField: NSSearchField = {
        let f = NSSearchField()
        f.placeholderString = "Search"
        f.controlSize = .small
        return f
    }()
    private let newButton: NSButton = {
        let b = NSButton()
        b.image = NSImage(systemSymbolName: "square.and.pencil", accessibilityDescription: "New Note")
        b.bezelStyle = .toolbar
        b.isBordered = false
        b.toolTip = "New Note"
        return b
    }()
    private let deleteButton: NSButton = {
        let b = NSButton()
        b.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete Note")
        b.bezelStyle = .toolbar
        b.isBordered = false
        b.toolTip = "Delete Note"
        b.isEnabled = false
        return b
    }()
    private let tableView = NSTableView()
    private let scrollView: NSScrollView = {
        let s = NSScrollView()
        s.hasVerticalScroller = true
        s.autohidesScrollers = true
        s.borderType = .noBorder
        return s
    }()

    // MARK: - Init

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
        setupToolbar()
        setupTableView()
        reload()
    }

    // MARK: - Layout

    private func setupToolbar() {
        newButton.target = self
        newButton.action = #selector(createNote)
        deleteButton.target = self
        deleteButton.action = #selector(deleteSelectedNote)
        searchField.delegate = self

        let toolbar = NSStackView(views: [newButton, deleteButton, searchField])
        toolbar.orientation = .horizontal
        toolbar.spacing = 4
        toolbar.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        toolbar.setHuggingPriority(.defaultLow, for: .horizontal)
        searchField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        newButton.setContentHuggingPriority(.required, for: .horizontal)
        deleteButton.setContentHuggingPriority(.required, for: .horizontal)

        let separator = NSBox()
        separator.boxType = .separator

        [toolbar, separator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            separator.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupTableView() {
        tableView.headerView = nil
        tableView.rowHeight = 58
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .regular
        tableView.delegate = self
        tableView.dataSource = self
        tableView.style = .plain

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NoteColumn"))
        column.isEditable = false
        tableView.addTableColumn(column)

        scrollView.documentView = tableView
    }

    // MARK: - Data

    private func reload() {
        allNotes = repository.allNotes()
        applyFilter(query: searchField.stringValue)
    }

    private func applyFilter(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            displayedNotes = allNotes
        } else {
            let matchIDs = Set(searchIndex.search(query: trimmed))
            displayedNotes = allNotes.filter { matchIDs.contains($0.id) }
        }
        tableView.reloadData()

        if let first = displayedNotes.first {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            delegate?.didSelectNote(first)
        } else {
            delegate?.didSelectNote(nil)
        }
    }

    // Called by RootSplitViewController after the editor autosaves.
    func noteWasUpdated(_ note: Note) {
        if let i = allNotes.firstIndex(where: { $0.id == note.id }) {
            allNotes[i] = note
        }
        if let i = displayedNotes.firstIndex(where: { $0.id == note.id }) {
            displayedNotes[i] = note
            tableView.reloadData(
                forRowIndexes: IndexSet(integer: i),
                columnIndexes: IndexSet(integer: 0)
            )
        }
    }

    // MARK: - Actions

    @objc private func createNote() {
        let id       = UUID().uuidString
        let filename = fileStore.filename(for: id)
        let now      = Date()
        let note     = Note(id: id, title: "Untitled", path: filename,
                            createdAt: now, updatedAt: now, preview: "", pinned: false)
        do {
            try fileStore.write(body: "", to: filename)
            try repository.insert(note)
            searchIndex.upsert(id: id, title: "Untitled", body: "")

            allNotes.insert(note, at: 0)
            displayedNotes.insert(note, at: 0)
            tableView.insertRows(at: IndexSet(integer: 0), withAnimation: .slideDown)
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            delegate?.didSelectNote(note)
        } catch {
            presentError(error)
        }
    }

    @objc private func deleteSelectedNote() {
        let row = tableView.selectedRow
        guard row >= 0, row < displayedNotes.count else { return }

        let note  = displayedNotes[row]
        let alert = NSAlert()
        alert.messageText     = "Delete \u{201C}\(note.title)\u{201D}?"
        alert.informativeText = "This note will be permanently deleted."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.buttons[0].hasDestructiveAction = true
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        do {
            try fileStore.delete(filename: note.path)
            try repository.delete(id: note.id)
            searchIndex.delete(id: note.id)

            displayedNotes.remove(at: row)
            allNotes.removeAll { $0.id == note.id }
            tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)

            let nextRow = min(row, displayedNotes.count - 1)
            if nextRow >= 0 {
                tableView.selectRowIndexes(IndexSet(integer: nextRow), byExtendingSelection: false)
                delegate?.didSelectNote(displayedNotes[nextRow])
            } else {
                delegate?.didSelectNote(nil)
            }
        } catch {
            presentError(error)
        }
    }
}

// MARK: - NSTableViewDataSource

extension NotesListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int { displayedNotes.count }
}

// MARK: - NSTableViewDelegate

extension NotesListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let note = displayedNotes[row]
        let id   = NSUserInterfaceItemIdentifier("NoteCell")
        if let cell = tableView.makeView(withIdentifier: id, owner: nil) as? NoteCellView {
            cell.configure(with: note)
            return cell
        }
        let cell = NoteCellView()
        cell.identifier = id
        cell.configure(with: note)
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        deleteButton.isEnabled = row >= 0
        if row >= 0, row < displayedNotes.count {
            delegate?.didSelectNote(displayedNotes[row])
        }
    }
}

// MARK: - NSSearchFieldDelegate

extension NotesListViewController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        applyFilter(query: searchField.stringValue)
    }
}

// MARK: - Note Cell View

private final class NoteCellView: NSTableCellView {
    private let titleLabel: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.lineBreakMode = .byTruncatingTail
        return l
    }()
    private let previewLabel: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.font = .systemFont(ofSize: 11)
        l.textColor = .secondaryLabelColor
        l.lineBreakMode = .byTruncatingTail
        return l
    }()
    private let dateLabel: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.font = .systemFont(ofSize: 10)
        l.textColor = .tertiaryLabelColor
        l.alignment = .right
        return l
    }()

    override init(frame: NSRect) {
        super.init(frame: frame)
        [titleLabel, previewLabel, dateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -6),

            dateLabel.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            dateLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),

            previewLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            previewLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            previewLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with note: Note) {
        titleLabel.stringValue   = note.title.isEmpty ? "Untitled" : note.title
        previewLabel.stringValue = note.preview
        dateLabel.stringValue    = DateDisplay.string(from: note.updatedAt)
    }
}

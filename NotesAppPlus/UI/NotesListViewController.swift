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

    // MARK: - Header subviews

    private let noteCountLabel: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = .secondaryLabelColor
        return l
    }()

    // Search field – used by the header and drives the list filter
    private let searchField: NSSearchField = {
        let f = NSSearchField()
        f.placeholderString = "Search"
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()

    // MARK: - List subviews

    private let tableView   = NSTableView()
    private let scrollView: NSScrollView = {
        let s = NSScrollView()
        s.hasVerticalScroller = true
        s.autohidesScrollers  = true
        s.borderType          = .noBorder
        return s
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

    override func loadView() { view = NSView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
        setupTableView()
        reload()
    }

    // MARK: - Layout

    private func setupHeader() {
        // Container – light white background
        let header = NSView()
        header.wantsLayer = true
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        // — Left side —
        let titleLabel = NSTextField(labelWithString: "Notes")
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = .labelColor

        noteCountLabel.stringValue = "0 notes"

        let titleStack = NSStackView(views: [titleLabel, noteCountLabel])
        titleStack.orientation = .vertical
        titleStack.alignment   = .leading
        titleStack.spacing     = 1

        let backBtn = RoundedIconButton(symbol: "chevron.left", size: 28, iconPt: 12, bg: false)
        backBtn.contentTintColor = .secondaryLabelColor

        let leftStack = NSStackView(views: [backBtn, titleStack])
        leftStack.orientation = .horizontal
        leftStack.spacing     = 6
        leftStack.alignment   = .centerY

        // — Right side: toolbar buttons —
        let toolSymbols = [
            ("square.and.pencil",      "New Note"),
            ("textformat",             "Format"),
            ("checklist",              "Checklist"),
            ("tablecells",             "Table"),
            ("paperclip",              "Attachment"),
            ("applepencil.and.scribble","Scribble"),
            ("square.and.arrow.up",    "Share"),
            ("ellipsis",               "More"),
        ]
        let toolButtons = toolSymbols.map { sym, _ -> NSView in
            let b = RoundedIconButton(symbol: sym, size: 30, iconPt: 14, bg: false)
            b.contentTintColor = .secondaryLabelColor
            return b
        }

        // Wire new-note button
        if let newBtn = toolButtons.first as? RoundedIconButton {
            newBtn.target = self
            newBtn.action = #selector(createNote)
        }

        let toolStack = NSStackView(views: toolButtons)
        toolStack.orientation = .horizontal
        toolStack.spacing     = 0

        // Search field
        searchField.delegate = self
        searchField.heightAnchor.constraint(equalToConstant: 28).isActive = true
        searchField.widthAnchor.constraint(equalToConstant: 180).isActive = true

        let rightStack = NSStackView(views: [toolStack, searchField])
        rightStack.orientation = .horizontal
        rightStack.spacing     = 8
        rightStack.alignment   = .centerY

        // — Assemble header —
        let hStack = NSStackView(views: [leftStack, rightStack])
        hStack.orientation = .horizontal
        hStack.alignment   = .centerY
        hStack.translatesAutoresizingMaskIntoConstraints = false

        leftStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rightStack.setContentHuggingPriority(.required, for: .horizontal)

        header.addSubview(hStack)

        // Separator
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sep)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 52),

            hStack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 14),
            hStack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -14),
            hStack.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            sep.topAnchor.constraint(equalTo: header.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: sep.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupTableView() {
        tableView.headerView  = nil
        tableView.rowHeight   = 58
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .regular
        tableView.style       = .plain
        tableView.delegate    = self
        tableView.dataSource  = self

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NoteColumn"))
        col.isEditable = false
        tableView.addTableColumn(col)

        scrollView.documentView = tableView
    }

    // MARK: - Data

    private func reload() {
        allNotes = repository.allNotes()
        applyFilter(query: searchField.stringValue)
    }

    private func applyFilter(query: String) {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty {
            displayedNotes = allNotes
        } else {
            let ids = Set(searchIndex.search(query: q))
            displayedNotes = allNotes.filter { ids.contains($0.id) }
        }
        tableView.reloadData()
        updateCount()

        if let first = displayedNotes.first {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            delegate?.didSelectNote(first)
        } else {
            delegate?.didSelectNote(nil)
        }
    }

    private func updateCount() {
        let n = displayedNotes.count
        noteCountLabel.stringValue = "\(n) \(n == 1 ? "note" : "notes")"
    }

    func noteWasUpdated(_ note: Note) {
        if let i = allNotes.firstIndex(where: { $0.id == note.id })        { allNotes[i]        = note }
        if let i = displayedNotes.firstIndex(where: { $0.id == note.id })  {
            displayedNotes[i] = note
            tableView.reloadData(forRowIndexes: IndexSet(integer: i), columnIndexes: IndexSet(integer: 0))
        }
    }

    // MARK: - Actions

    @objc private func createNote() {
        let id   = UUID().uuidString
        let file = fileStore.filename(for: id)
        let now  = Date()
        let note = Note(id: id, title: "Untitled", path: file,
                        createdAt: now, updatedAt: now, preview: "", pinned: false)
        do {
            try fileStore.write(body: "", to: file)
            try repository.insert(note)
            searchIndex.upsert(id: id, title: "Untitled", body: "")
            allNotes.insert(note, at: 0)
            displayedNotes.insert(note, at: 0)
            tableView.insertRows(at: IndexSet(integer: 0), withAnimation: .slideDown)
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            delegate?.didSelectNote(note)
            updateCount()
        } catch { presentError(error) }
    }

    private func deleteNote(at row: Int) {
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
            let next = min(row, displayedNotes.count - 1)
            if next >= 0 {
                tableView.selectRowIndexes(IndexSet(integer: next), byExtendingSelection: false)
                delegate?.didSelectNote(displayedNotes[next])
            } else {
                delegate?.didSelectNote(nil)
            }
            updateCount()
        } catch { presentError(error) }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 51 { // Delete key
            deleteNote(at: tableView.selectedRow)
        } else {
            super.keyDown(with: event)
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
            cell.configure(with: note); return cell
        }
        let cell = NoteCellView(); cell.identifier = id; cell.configure(with: note)
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
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
            $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0)
        }
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -6),

            dateLabel.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            dateLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),

            previewLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            previewLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            previewLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with note: Note) {
        titleLabel.stringValue   = note.title.isEmpty ? "Untitled" : note.title
        previewLabel.stringValue = note.preview
        dateLabel.stringValue    = DateDisplay.string(from: note.updatedAt)
    }
}

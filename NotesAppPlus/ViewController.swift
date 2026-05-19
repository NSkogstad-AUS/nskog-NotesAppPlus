//
//  ViewController.swift
//  NotesAppPlus
//
//  Created by Nicolai Skogstad on 17/5/2026.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        buildNotesShell()
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        view.window?.title = "NotesAppPlus"
        view.window?.minSize = NSSize(width: 920, height: 580)
    }
    
    private func buildNotesShell() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        let headerBar = makeHeaderBar()
        let sidebar = makeSidebar()
        let notesList = makeNotesList()
        let editorArea = makeEditorArea()
        
        [headerBar, sidebar, notesList, editorArea].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.heightAnchor.constraint(equalToConstant: 64),
            
            sidebar.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            sidebar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sidebar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sidebar.widthAnchor.constraint(equalToConstant: 220),
            
            notesList.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            notesList.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            notesList.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            notesList.widthAnchor.constraint(equalToConstant: 280),
            
            editorArea.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            editorArea.leadingAnchor.constraint(equalTo: notesList.trailingAnchor),
            editorArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editorArea.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func makeHeaderBar() -> NSView {
        let container = NSVisualEffectView()
        container.material = .headerView
        container.blendingMode = .withinWindow
        container.state = .active
        
        let leftControls = NSStackView(views: [
            makeIconButton(symbolName: "sidebar.left", accessibilityLabel: "Toggle Sidebar"),
            makeIconButton(symbolName: "square.and.pencil", accessibilityLabel: "New Note"),
            makeIconButton(symbolName: "folder.badge.plus", accessibilityLabel: "New Folder")
        ])
        leftControls.orientation = .horizontal
        leftControls.spacing = 10
        leftControls.alignment = .centerY
        
        let titleStack = NSStackView()
        titleStack.orientation = .vertical
        titleStack.spacing = 2
        titleStack.alignment = .leading
        
        let titleLabel = makeLabel("Notes", font: .systemFont(ofSize: 17, weight: .semibold), color: .labelColor)
        let subtitleLabel = makeLabel("All iCloud notes", font: .systemFont(ofSize: 12, weight: .regular), color: .secondaryLabelColor)
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)
        
        let searchField = NSSearchField()
        searchField.placeholderString = "Search"
        searchField.translatesAutoresizingMaskIntoConstraints = false
        
        let rightControls = NSStackView(views: [
            makeIconButton(symbolName: "textformat", accessibilityLabel: "Formatting"),
            makeIconButton(symbolName: "checklist", accessibilityLabel: "Checklist"),
            makeIconButton(symbolName: "square.and.arrow.up", accessibilityLabel: "Share")
        ])
        rightControls.orientation = .horizontal
        rightControls.spacing = 8
        rightControls.alignment = .centerY
        
        [leftControls, titleStack, searchField, rightControls].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            leftControls.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            leftControls.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            titleStack.leadingAnchor.constraint(equalTo: leftControls.trailingAnchor, constant: 22),
            titleStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            searchField.trailingAnchor.constraint(equalTo: rightControls.leadingAnchor, constant: -18),
            searchField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            searchField.widthAnchor.constraint(equalToConstant: 240),
            
            rightControls.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            rightControls.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    private func makeSidebar() -> NSView {
        let container = NSVisualEffectView()
        container.material = .sidebar
        container.blendingMode = .withinWindow
        container.state = .active
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 18, bottom: 24, right: 18)
        
        stack.addArrangedSubview(makeSectionLabel("ICLOUD"))
        stack.addArrangedSubview(makeSidebarRow(symbolName: "note.text", title: "All Notes", count: "24", isSelected: true))
        stack.addArrangedSubview(makeSidebarRow(symbolName: "folder", title: "Work", count: "8", isSelected: false))
        stack.addArrangedSubview(makeSidebarRow(symbolName: "folder", title: "Personal", count: "11", isSelected: false))
        stack.addArrangedSubview(makeSidebarRow(symbolName: "trash", title: "Recently Deleted", count: "3", isSelected: false))
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    private func makeNotesList() -> NSView {
        let container = RoundedPanelView(fillColor: NSColor.controlBackgroundColor, borderColor: NSColor.separatorColor)
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 14, bottom: 18, right: 14)
        
        stack.addArrangedSubview(makeLabel("Today", font: .systemFont(ofSize: 13, weight: .semibold), color: .secondaryLabelColor))
        stack.addArrangedSubview(makeNotePreview(title: "Meeting notes", preview: "Project kickoff, open questions, next steps...", date: "9:41 AM", isSelected: true))
        stack.addArrangedSubview(makeNotePreview(title: "Shopping", preview: "Coffee, oat milk, lemons, printer paper", date: "Yesterday", isSelected: false))
        stack.addArrangedSubview(makeNotePreview(title: "Ideas", preview: "Small improvements for the notes editor", date: "Mon", isSelected: false))
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    private func makeEditorArea() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        
        let title = makeLabel("Meeting notes", font: .systemFont(ofSize: 28, weight: .bold), color: .labelColor)
        let date = makeLabel("19 May 2026 at 9:41 AM", font: .systemFont(ofSize: 13), color: .tertiaryLabelColor)
        let rule = NSBox()
        rule.boxType = .separator
        
        let body = makeLabel("Header and styling shell only. Editor interactions and persistence will come next.", font: .systemFont(ofSize: 16), color: .secondaryLabelColor)
        body.lineBreakMode = .byWordWrapping
        
        [title, date, rule, body].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: container.topAnchor, constant: 46),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 48),
            title.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -48),
            
            date.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            date.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            
            rule.topAnchor.constraint(equalTo: date.bottomAnchor, constant: 22),
            rule.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            rule.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -48),
            
            body.topAnchor.constraint(equalTo: rule.bottomAnchor, constant: 28),
            body.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -48)
        ])
        
        return container
    }
    
    private func makeSidebarRow(symbolName: String, title: String, count: String, isSelected: Bool) -> NSView {
        let row = RoundedPanelView(
            fillColor: isSelected ? NSColor.selectedContentBackgroundColor.withAlphaComponent(0.18) : .clear,
            borderColor: .clear
        )
        
        let icon = NSImageView(image: NSImage(systemSymbolName: symbolName, accessibilityDescription: title) ?? NSImage())
        icon.contentTintColor = isSelected ? .controlAccentColor : .secondaryLabelColor
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = makeLabel(title, font: .systemFont(ofSize: 14, weight: isSelected ? .semibold : .regular), color: .labelColor)
        let countLabel = makeLabel(count, font: .systemFont(ofSize: 12, weight: .medium), color: .secondaryLabelColor)
        
        [icon, titleLabel, countLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 34),
            
            icon.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 10),
            icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
            
            titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 9),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            
            countLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -10),
            countLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            countLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])
        
        return row
    }
    
    private func makeNotePreview(title: String, preview: String, date: String, isSelected: Bool) -> NSView {
        let card = RoundedPanelView(
            fillColor: isSelected ? NSColor.controlAccentColor.withAlphaComponent(0.14) : NSColor.textBackgroundColor,
            borderColor: isSelected ? NSColor.controlAccentColor.withAlphaComponent(0.18) : NSColor.separatorColor
        )
        
        let titleLabel = makeLabel(title, font: .systemFont(ofSize: 14, weight: .semibold), color: .labelColor)
        let dateLabel = makeLabel(date, font: .systemFont(ofSize: 11, weight: .medium), color: .tertiaryLabelColor)
        let previewLabel = makeLabel(preview, font: .systemFont(ofSize: 12), color: .secondaryLabelColor)
        previewLabel.lineBreakMode = .byTruncatingTail
        
        [titleLabel, dateLabel, previewLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 78),
            
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            
            dateLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            dateLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            dateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            
            previewLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            previewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            previewLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12)
        ])
        
        return card
    }
    
    private func makeIconButton(symbolName: String, accessibilityLabel: String) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
        button.bezelStyle = .rounded
        button.isBordered = true
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = accessibilityLabel
        button.setAccessibilityLabel(accessibilityLabel)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        return button
    }
    
    private func makeSectionLabel(_ text: String) -> NSTextField {
        let label = makeLabel(text, font: .systemFont(ofSize: 11, weight: .semibold), color: .tertiaryLabelColor)
        label.maximumNumberOfLines = 1
        return label
    }
    
    private func makeLabel(_ text: String, font: NSFont, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        label.lineBreakMode = .byTruncatingTail
        return label
    }
}

private final class RoundedPanelView: NSView {
    private let fillColor: NSColor
    private let borderColor: NSColor
    
    init(fillColor: NSColor, borderColor: NSColor) {
        self.fillColor = fillColor
        self.borderColor = borderColor
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
        layer?.borderWidth = borderColor == .clear ? 0 : 1
        layer?.backgroundColor = fillColor.cgColor
        layer?.borderColor = borderColor.cgColor
    }
    
    required init?(coder: NSCoder) {
        nil
    }
}

//
//  ViewController.swift
//  NotesAppPlus
//
//  Created by Nicolai Skogstad on 17/5/2026.
//

import Cocoa

class ViewController: NSViewController {
    private let noteTitleLabel = NSTextField(labelWithString: "Meeting notes")
    private let searchField = NSSearchField()
    private let sidebar = NSVisualEffectView()
    private var sidebarWidthConstraint: NSLayoutConstraint?
    private var isSidebarVisible = false
    private var newNoteCount = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildNotesHeader()
    }
    
    override var representedObject: Any? {
        didSet {
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        view.window?.title = "NotesAppPlus"
        view.window?.minSize = NSSize(width: 760, height: 460)
    }
    
    private func buildNotesHeader() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        
        let headerBar = makeHeaderBar()
        configureSidebar()
        
        [headerBar, sidebar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        let sidebarWidthConstraint = sidebar.widthAnchor.constraint(equalToConstant: 0)
        self.sidebarWidthConstraint = sidebarWidthConstraint
        
        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.heightAnchor.constraint(equalToConstant: 52),
            
            sidebar.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            sidebar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sidebar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sidebarWidthConstraint
        ])
    }
    
    private func makeHeaderBar() -> NSView {
        let container = NSVisualEffectView()
        container.material = .headerView
        container.blendingMode = .withinWindow
        container.state = .active
        
        let sidebarButton = makeHeaderButton(
            symbolName: "sidebar.left",
            accessibilityLabel: "Toggle Sidebar",
            action: #selector(toggleSidebar)
        )
        
        let newNoteButton = makeHeaderButton(
            symbolName: "square.and.pencil",
            accessibilityLabel: "New Note",
            action: #selector(createNewNote)
        )
        
        let leftControls = NSStackView(views: [sidebarButton, newNoteButton])
        leftControls.orientation = .horizontal
        leftControls.spacing = 8
        leftControls.alignment = .centerY
        
        noteTitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        noteTitleLabel.textColor = .labelColor
        noteTitleLabel.lineBreakMode = .byTruncatingTail
        noteTitleLabel.alignment = .center
        noteTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        searchField.placeholderString = "Search"
        searchField.isHidden = true
        searchField.target = self
        searchField.action = #selector(searchChanged)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        
        let searchButton = makeHeaderButton(
            symbolName: "magnifyingglass",
            accessibilityLabel: "Search",
            action: #selector(toggleSearch)
        )
        
        let moreButton = makeHeaderButton(
            symbolName: "ellipsis.circle",
            accessibilityLabel: "More Settings",
            action: #selector(showSettingsMenu(_:))
        )
        
        let rightControls = NSStackView(views: [searchField, searchButton, moreButton])
        rightControls.orientation = .horizontal
        rightControls.spacing = 8
        rightControls.alignment = .centerY
        
        [leftControls, noteTitleLabel, rightControls].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            leftControls.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            leftControls.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            noteTitleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            noteTitleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            noteTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leftControls.trailingAnchor, constant: 18),
            noteTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightControls.leadingAnchor, constant: -18),
            
            rightControls.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            rightControls.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            searchField.widthAnchor.constraint(equalToConstant: 210)
        ])
        
        return container
    }
    
    private func configureSidebar() {
        sidebar.material = .sidebar
        sidebar.blendingMode = .withinWindow
        sidebar.state = .active
        sidebar.isHidden = true
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 5
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 14, bottom: 16, right: 10)
        
        stack.addArrangedSubview(makeSidebarRow(symbolName: "note.text", title: "Quick Notes", count: "5", isSelected: false))
        stack.addArrangedSubview(makeSidebarRow(symbolName: "person.2", title: "Shared", count: "2", isSelected: false))
        stack.addArrangedSubview(makeSidebarSectionLabel("iCloud"))
        stack.addArrangedSubview(makeSidebarRow(symbolName: "folder", title: "Notes", count: "64", isSelected: true))
        stack.addArrangedSubview(makeSidebarRow(symbolName: "trash", title: "Recently Deleted", count: "2", isSelected: false))
        stack.addArrangedSubview(makeSidebarSectionLabel("Google"))
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: sidebar.topAnchor),
            stack.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor)
        ])
    }
    
    @objc private func toggleSidebar() {
        isSidebarVisible.toggle()
        sidebar.isHidden = false
        sidebarWidthConstraint?.constant = isSidebarVisible ? 230 : 0
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.allowsImplicitAnimation = true
            view.layoutSubtreeIfNeeded()
        } completionHandler: { [weak self] in
            self?.sidebar.isHidden = self?.isSidebarVisible == false
        }
    }
    
    @objc private func createNewNote() {
        newNoteCount += 1
        noteTitleLabel.stringValue = "Untitled Note \(newNoteCount)"
        searchField.stringValue = ""
        view.window?.makeFirstResponder(nil)
    }
    
    @objc private func toggleSearch() {
        searchField.isHidden.toggle()
        
        if searchField.isHidden {
            searchField.stringValue = ""
            noteTitleLabel.stringValue = "Meeting notes"
            view.window?.makeFirstResponder(nil)
        } else {
            view.window?.makeFirstResponder(searchField)
        }
    }
    
    @objc private func searchChanged() {
        let searchText = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        noteTitleLabel.stringValue = searchText.isEmpty ? "Meeting notes" : "Search: \(searchText)"
    }
    
    @objc private func showSettingsMenu(_ sender: NSButton) {
        let menu = NSMenu()
        menu.addItem(withTitle: "View as List", action: #selector(selectSettingsMenuItem(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Sort by Date", action: #selector(selectSettingsMenuItem(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Group by Date", action: #selector(selectSettingsMenuItem(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "View Attachments", action: #selector(selectSettingsMenuItem(_:)), keyEquivalent: "")
        
        menu.items.forEach { $0.target = self }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 6), in: sender)
    }
    
    @objc private func selectSettingsMenuItem(_ sender: NSMenuItem) {
        noteTitleLabel.stringValue = sender.title
    }
    
    @objc private func selectSidebarItem(_ sender: NSButton) {
        noteTitleLabel.stringValue = sender.title
    }
    
    private func makeHeaderButton(symbolName: String, accessibilityLabel: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
        button.bezelStyle = .texturedRounded
        button.isBordered = true
        button.imageScaling = .scaleProportionallyDown
        button.target = self
        button.action = action
        button.toolTip = accessibilityLabel
        button.setAccessibilityLabel(accessibilityLabel)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        return button
    }
    
    private func makeSidebarSectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: 26)
        ])
        
        return label
    }
    
    private func makeSidebarRow(symbolName: String, title: String, count: String, isSelected: Bool) -> NSView {
        let row = NSView()
        row.wantsLayer = true
        row.layer?.backgroundColor = isSelected ? NSColor.controlColor.cgColor : NSColor.clear.cgColor
        row.layer?.cornerRadius = 5
        
        let iconView = NSImageView(image: NSImage(systemSymbolName: symbolName, accessibilityDescription: title) ?? NSImage())
        iconView.contentTintColor = isSelected ? .systemRed : .secondaryLabelColor
        
        let titleButton = NSButton(title: title, target: self, action: #selector(selectSidebarItem(_:)))
        titleButton.bezelStyle = .regularSquare
        titleButton.isBordered = false
        titleButton.alignment = .left
        titleButton.font = .systemFont(ofSize: 12, weight: isSelected ? .semibold : .regular)
        titleButton.contentTintColor = isSelected ? .systemRed : .labelColor
        
        let countLabel = NSTextField(labelWithString: count)
        countLabel.font = .systemFont(ofSize: 12)
        countLabel.textColor = .tertiaryLabelColor
        countLabel.alignment = .right
        
        [iconView, titleButton, countLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 25),
            
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),
            
            titleButton.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            titleButton.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            titleButton.heightAnchor.constraint(equalToConstant: 20),
            
            countLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleButton.trailingAnchor, constant: 8),
            countLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -7),
            countLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 24)
        ])
        
        return row
    }
}

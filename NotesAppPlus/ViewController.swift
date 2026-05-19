//
//  ViewController.swift
//  NotesAppPlus
//
//  Created by Nicolai Skogstad on 17/5/2026.
//

import Cocoa

class ViewController: NSViewController {
    private let noteTitleLabel = NSTextField(labelWithString: "Meeting notes")
    private let sidebar = NSVisualEffectView()
    private let trackedNotesStack = NSStackView()
    private var sidebarLeadingConstraint: NSLayoutConstraint?
    private var headerControlsLeadingConstraint: NSLayoutConstraint?
    private var isSidebarVisible = false
    private var newNoteCount = 1
    private var selectedNoteIndex = 0
    private var trackedNotes = ["Meeting notes"]
    private var hasConfiguredWindowChrome = false
    private var trafficLightOriginY: CGFloat?
    
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
        
        configureWindowChrome()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        if hasConfiguredWindowChrome {
            positionTrafficLightButtons()
        }
    }
    
    private func buildNotesHeader() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        
        let headerBar = makeHeaderBar()
        configureSidebar()
        
        [sidebar, headerBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        let sidebarLeadingConstraint = sidebar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -238)
        self.sidebarLeadingConstraint = sidebarLeadingConstraint
        
        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.heightAnchor.constraint(equalToConstant: 44),
            
            sidebar.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            sidebarLeadingConstraint,
            sidebar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            sidebar.widthAnchor.constraint(equalToConstant: 230)
        ])
    }
    
    private func makeHeaderBar() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        
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
        
        [leftControls, noteTitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        
        let headerControlsLeadingConstraint = leftControls.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 96)
        self.headerControlsLeadingConstraint = headerControlsLeadingConstraint
        
        NSLayoutConstraint.activate([
            headerControlsLeadingConstraint,
            leftControls.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 3),
            
            noteTitleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            noteTitleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            noteTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leftControls.trailingAnchor, constant: 18),
            noteTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -18)
        ])
        
        return container
    }
    
    private func configureWindowChrome() {
        guard let window = view.window else {
            return
        }
        
        window.title = "NotesAppPlus"
        window.minSize = NSSize(width: 760, height: 460)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        hasConfiguredWindowChrome = true
        positionTrafficLightButtons()
    }
    
    private func positionTrafficLightButtons() {
        guard
            let closeButton = view.window?.standardWindowButton(.closeButton),
            let minimizeButton = view.window?.standardWindowButton(.miniaturizeButton),
            let zoomButton = view.window?.standardWindowButton(.zoomButton)
        else {
            return
        }
        
        let originX: CGFloat = 20
        let spacing: CGFloat = 22
        let originY = trafficLightOriginY ?? closeButton.frame.origin.y - 10
        trafficLightOriginY = originY
        
        closeButton.setFrameOrigin(NSPoint(x: originX, y: originY))
        minimizeButton.setFrameOrigin(NSPoint(x: originX + spacing, y: originY))
        zoomButton.setFrameOrigin(NSPoint(x: originX + (spacing * 2), y: originY))
    }
    
    private func configureSidebar() {
        sidebar.material = .sidebar
        sidebar.blendingMode = .withinWindow
        sidebar.state = .active
        sidebar.isHidden = true
        sidebar.wantsLayer = true
        sidebar.layer?.cornerRadius = 18
        sidebar.layer?.cornerCurve = .continuous
        sidebar.layer?.borderColor = NSColor.separatorColor.cgColor
        sidebar.layer?.borderWidth = 1
        sidebar.layer?.shadowColor = NSColor.black.cgColor
        sidebar.layer?.shadowOpacity = 0.18
        sidebar.layer?.shadowRadius = 18
        sidebar.layer?.shadowOffset = NSSize(width: 0, height: 6)
        
        trackedNotesStack.orientation = .vertical
        trackedNotesStack.spacing = 5
        trackedNotesStack.edgeInsets = NSEdgeInsets(top: 54, left: 14, bottom: 16, right: 10)
        refreshTrackedNotes()
        
        trackedNotesStack.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(trackedNotesStack)
        
        NSLayoutConstraint.activate([
            trackedNotesStack.topAnchor.constraint(equalTo: sidebar.topAnchor),
            trackedNotesStack.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor),
            trackedNotesStack.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor)
        ])
    }
    
    @objc private func toggleSidebar() {
        isSidebarVisible.toggle()
        sidebar.isHidden = false
        sidebarLeadingConstraint?.constant = isSidebarVisible ? 8 : -238
        headerControlsLeadingConstraint?.constant = isSidebarVisible ? 198 : 96
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.24
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            view.layoutSubtreeIfNeeded()
        } completionHandler: { [weak self] in
            self?.sidebar.isHidden = self?.isSidebarVisible == false
        }
    }
    
    @objc private func createNewNote() {
        newNoteCount += 1
        let noteTitle = "Untitled Note \(newNoteCount)"
        trackedNotes.append(noteTitle)
        selectedNoteIndex = trackedNotes.count - 1
        noteTitleLabel.stringValue = noteTitle
        refreshTrackedNotes()
        
        if !isSidebarVisible {
            toggleSidebar()
        }
        
        view.window?.makeFirstResponder(nil)
    }
    
    @objc private func selectSidebarItem(_ sender: NSButton) {
        selectedNoteIndex = sender.tag
        noteTitleLabel.stringValue = trackedNotes[selectedNoteIndex]
        refreshTrackedNotes()
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
    
    private func refreshTrackedNotes() {
        trackedNotesStack.arrangedSubviews.forEach {
            trackedNotesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        trackedNotes.enumerated().forEach { index, title in
            trackedNotesStack.addArrangedSubview(makeTrackedNoteRow(title: title, index: index, isSelected: index == selectedNoteIndex))
        }
    }
    
    private func makeTrackedNoteRow(title: String, index: Int, isSelected: Bool) -> NSView {
        let row = NSView()
        row.wantsLayer = true
        row.layer?.backgroundColor = isSelected ? NSColor.controlColor.cgColor : NSColor.clear.cgColor
        row.layer?.cornerRadius = 5
        
        let iconView = NSImageView(image: NSImage(systemSymbolName: "note.text", accessibilityDescription: title) ?? NSImage())
        iconView.contentTintColor = isSelected ? .systemRed : .secondaryLabelColor
        
        let titleButton = NSButton(title: title, target: self, action: #selector(selectSidebarItem(_:)))
        titleButton.bezelStyle = .regularSquare
        titleButton.isBordered = false
        titleButton.alignment = .left
        titleButton.font = .systemFont(ofSize: 12, weight: isSelected ? .semibold : .regular)
        titleButton.contentTintColor = isSelected ? .systemRed : .labelColor
        titleButton.lineBreakMode = .byTruncatingTail
        titleButton.tag = index
        
        [iconView, titleButton].forEach {
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
            titleButton.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -8),
            titleButton.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            titleButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return row
    }
}

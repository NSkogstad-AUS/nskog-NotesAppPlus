//
//  ViewController.swift
//  NotesAppPlus
//
//  Created by Nicolai Skogstad on 17/5/2026.
//

import Cocoa

class ViewController: NSViewController {
    private let sidebarInset: CGFloat = 8
    private let minimumSidebarWidth: CGFloat = 190
    private let maximumSidebarWidth: CGFloat = 360
    private let noteTitleLabel = NSTextField(labelWithString: "Meeting notes")
    private let sidebar = NSVisualEffectView()
    private let sidebarResizeHandle = SidebarResizeHandleView()
    private let trackedNotesStack = NSStackView()
    private var sidebarLeadingConstraint: NSLayoutConstraint?
    private var sidebarWidthConstraint: NSLayoutConstraint?
    private var closedHeaderControlsLeadingConstraint: NSLayoutConstraint?
    private var attachedHeaderControlsTrailingConstraint: NSLayoutConstraint?
    private var titleClosedLeadingConstraint: NSLayoutConstraint?
    private var titleOpenLeadingConstraint: NSLayoutConstraint?
    private var isSidebarVisible = false
    private var selectedNoteIndex = 0
    private var trackedNotes = ["Meeting notes"]
    private var trafficLightOriginY: CGFloat?
    private var sidebarResizeStartWidth: CGFloat?
    private var windowWasResizableBeforeSidebarResize = false
    
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
    
    private func buildNotesHeader() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        
        let headerBar = makeHeaderBar()
        configureSidebar()
        
        [sidebar, headerBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        let sidebarWidthConstraint = sidebar.widthAnchor.constraint(equalToConstant: 230)
        let sidebarLeadingConstraint = sidebar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: closedSidebarLeadingConstant(for: sidebarWidthConstraint.constant))
        self.sidebarWidthConstraint = sidebarWidthConstraint
        self.sidebarLeadingConstraint = sidebarLeadingConstraint
        
        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.heightAnchor.constraint(equalToConstant: 44),
            
            sidebar.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            sidebarLeadingConstraint,
            sidebar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            sidebarWidthConstraint
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
        
        let leftControls = NSStackView(views: [sidebarButton])
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
        
        let closedHeaderControlsLeadingConstraint = leftControls.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 96)
        let attachedHeaderControlsTrailingConstraint = leftControls.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor, constant: -40)
        self.closedHeaderControlsLeadingConstraint = closedHeaderControlsLeadingConstraint
        self.attachedHeaderControlsTrailingConstraint = attachedHeaderControlsTrailingConstraint
        attachedHeaderControlsTrailingConstraint.isActive = false
        
        let titleClosedLeadingConstraint = noteTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leftControls.trailingAnchor, constant: 18)
        let titleOpenLeadingConstraint = noteTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: sidebar.trailingAnchor, constant: 28)
        self.titleClosedLeadingConstraint = titleClosedLeadingConstraint
        self.titleOpenLeadingConstraint = titleOpenLeadingConstraint
        titleOpenLeadingConstraint.isActive = false
        
        NSLayoutConstraint.activate([
            closedHeaderControlsLeadingConstraint,
            leftControls.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 3),
            
            noteTitleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            noteTitleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleClosedLeadingConstraint,
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
        window.isMovableByWindowBackground = false
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
        sidebarResizeHandle.wantsLayer = true
        sidebarResizeHandle.layer?.backgroundColor = NSColor.clear.cgColor
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
        sidebarResizeHandle.onDragStarted = { [weak self] in
            self?.beginSidebarResize()
        }
        sidebarResizeHandle.onDragChanged = { [weak self] totalDeltaX in
            self?.resizeSidebar(by: totalDeltaX)
        }
        sidebarResizeHandle.onDragEnded = { [weak self] in
            self?.endSidebarResize()
        }
        
        trackedNotesStack.orientation = .vertical
        trackedNotesStack.spacing = 5
        trackedNotesStack.edgeInsets = NSEdgeInsets(top: 54, left: 14, bottom: 16, right: 10)
        refreshTrackedNotes()
        
        trackedNotesStack.translatesAutoresizingMaskIntoConstraints = false
        sidebarResizeHandle.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(trackedNotesStack)
        sidebar.addSubview(sidebarResizeHandle)
        
        NSLayoutConstraint.activate([
            trackedNotesStack.topAnchor.constraint(equalTo: sidebar.topAnchor),
            trackedNotesStack.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor),
            trackedNotesStack.trailingAnchor.constraint(equalTo: sidebarResizeHandle.leadingAnchor),
            
            sidebarResizeHandle.topAnchor.constraint(equalTo: sidebar.topAnchor),
            sidebarResizeHandle.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            sidebarResizeHandle.bottomAnchor.constraint(equalTo: sidebar.bottomAnchor),
            sidebarResizeHandle.widthAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    @objc private func toggleSidebar() {
        isSidebarVisible.toggle()
        sidebar.isHidden = false
        updateSidebarRelatedConstraints()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.24
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            view.layoutSubtreeIfNeeded()
        } completionHandler: { [weak self] in
            self?.sidebar.isHidden = self?.isSidebarVisible == false
        }
    }
    
    @objc private func selectSidebarItem(_ sender: NSButton) {
        selectedNoteIndex = sender.tag
        noteTitleLabel.stringValue = trackedNotes[selectedNoteIndex]
        refreshTrackedNotes()
    }
    
    private func makeHeaderButton(symbolName: String, accessibilityLabel: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.imageScaling = .scaleProportionallyDown
        button.contentTintColor = .controlAccentColor
        button.wantsLayer = true
        button.layer?.cornerRadius = 14
        button.layer?.cornerCurve = .continuous
        button.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.65).cgColor
        button.layer?.borderColor = NSColor.separatorColor.cgColor
        button.layer?.borderWidth = 1
        button.target = self
        button.action = action
        button.toolTip = accessibilityLabel
        button.setAccessibilityLabel(accessibilityLabel)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 28),
            button.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        return button
    }
    
    private func resizeSidebar(by deltaX: CGFloat) {
        guard isSidebarVisible, let sidebarWidthConstraint else {
            return
        }
        
        let startingWidth = sidebarResizeStartWidth ?? sidebarWidthConstraint.constant
        let proposedWidth = startingWidth + deltaX
        sidebarWidthConstraint.constant = min(max(proposedWidth, minimumSidebarWidth), maximumSidebarWidth)
        updateSidebarRelatedConstraints()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            view.layoutSubtreeIfNeeded()
        }
    }
    
    private func beginSidebarResize() {
        sidebarResizeStartWidth = sidebarWidthConstraint?.constant
        
        guard let window = view.window else {
            return
        }
        
        windowWasResizableBeforeSidebarResize = window.styleMask.contains(.resizable)
        window.styleMask.remove(.resizable)
    }
    
    private func endSidebarResize() {
        sidebarResizeStartWidth = nil
        
        guard windowWasResizableBeforeSidebarResize, let window = view.window else {
            return
        }
        
        window.styleMask.insert(.resizable)
    }
    
    private func updateSidebarRelatedConstraints() {
        let width = sidebarWidthConstraint?.constant ?? 230
        sidebarLeadingConstraint?.constant = isSidebarVisible ? sidebarInset : closedSidebarLeadingConstant(for: width)
        closedHeaderControlsLeadingConstraint?.isActive = !isSidebarVisible
        attachedHeaderControlsTrailingConstraint?.isActive = isSidebarVisible
        titleClosedLeadingConstraint?.isActive = !isSidebarVisible
        titleOpenLeadingConstraint?.isActive = isSidebarVisible
    }
    
    private func closedSidebarLeadingConstant(for width: CGFloat) -> CGFloat {
        -(width + sidebarInset)
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

private final class SidebarResizeHandleView: NSView {
    var onDragStarted: (() -> Void)?
    var onDragChanged: ((CGFloat) -> Void)?
    var onDragEnded: (() -> Void)?
    private var startingDragX: CGFloat?
    
    override var acceptsFirstResponder: Bool {
        true
    }
    
    override var mouseDownCanMoveWindow: Bool {
        false
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }
    
    override func mouseDown(with event: NSEvent) {
        startingDragX = event.locationInWindow.x
        onDragStarted?()
    }
    
    override func mouseDragged(with event: NSEvent) {
        let currentX = event.locationInWindow.x
        guard let startingDragX else {
            self.startingDragX = currentX
            return
        }
        
        onDragChanged?(currentX - startingDragX)
    }
    
    override func mouseUp(with event: NSEvent) {
        startingDragX = nil
        onDragEnded?()
    }
    
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }
}

import AppKit

// MARK: - Data

private struct SidebarItem {
    let symbol: String
    let label: String
    let count: Int
    var isSelected: Bool = false
    var isRed: Bool = false
}

private struct SidebarSection {
    let header: String?
    let items: [SidebarItem]
}

private let sidebarSections: [SidebarSection] = [
    SidebarSection(header: nil, items: [
        SidebarItem(symbol: "note.text",    label: "Quick Notes", count: 5),
        SidebarItem(symbol: "person.2.fill",label: "Shared",      count: 2),
    ]),
    SidebarSection(header: "iCloud", items: [
        SidebarItem(symbol: "folder.fill",  label: "Notes",            count: 64, isSelected: true, isRed: true),
        SidebarItem(symbol: "trash",        label: "Recently Deleted", count: 2),
    ]),
    SidebarSection(header: "Google", items: []),
]

// MARK: - SidebarViewController

final class SidebarViewController: NSViewController {

    override func loadView() {
        let ve = NSVisualEffectView()
        ve.material     = .sidebar
        ve.blendingMode = .behindWindow
        ve.state        = .active
        view = ve
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildContent()
    }

    private func buildContent() {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = false
        scroll.borderType          = .noBorder
        scroll.drawsBackground     = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment   = .leading
        stack.spacing     = 1
        stack.edgeInsets  = NSEdgeInsets(top: 6, left: 0, bottom: 20, right: 0)
        stack.translatesAutoresizingMaskIntoConstraints = false

        for section in sidebarSections {
            if let header = section.header {
                stack.addArrangedSubview(makeSectionHeader(header))
            }
            for item in section.items {
                let row = SidebarRowView(item: item)
                row.translatesAutoresizingMaskIntoConstraints = false
                row.heightAnchor.constraint(equalToConstant: 26).isActive = true
                stack.addArrangedSubview(row)
            }
            let spacer = NSView()
            spacer.translatesAutoresizingMaskIntoConstraints = false
            spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
            stack.addArrangedSubview(spacer)
        }

        scroll.documentView = stack

        let clip = scroll.contentView
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo:  clip.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
            stack.topAnchor.constraint(equalTo:      clip.topAnchor),
        ])
    }

    private func makeSectionHeader(_ text: String) -> NSView {
        let label = NSTextField(labelWithString: text.uppercased())
        label.font      = NSFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = NSColor.tertiaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 22).isActive = true
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }
}

// MARK: - SidebarRowView

private final class SidebarRowView: NSView {
    private let item: SidebarItem

    init(item: SidebarItem) {
        self.item = item
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        wantsLayer = true

        if item.isSelected {
            let bg = NSView()
            bg.wantsLayer = true
            bg.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.1).cgColor
            bg.layer?.cornerRadius    = 6
            bg.translatesAutoresizingMaskIntoConstraints = false
            addSubview(bg)
            NSLayoutConstraint.activate([
                bg.leadingAnchor.constraint(equalTo:  leadingAnchor,  constant: 8),
                bg.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
                bg.topAnchor.constraint(equalTo:      topAnchor,      constant: 1),
                bg.bottomAnchor.constraint(equalTo:   bottomAnchor,   constant: -1),
            ])
        }

        let iconCfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        let icon    = NSImageView()
        icon.image           = NSImage(systemSymbolName: item.symbol, accessibilityDescription: nil)?
                                    .withSymbolConfiguration(iconCfg)
        icon.contentTintColor = item.isRed ? NSColor.systemRed : NSColor.secondaryLabelColor
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant:  16).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        addSubview(icon)

        let nameLabel = NSTextField(labelWithString: item.label)
        nameLabel.font      = NSFont.systemFont(ofSize: 13, weight: item.isSelected ? .semibold : .regular)
        nameLabel.textColor = item.isRed ? NSColor.systemRed : NSColor.labelColor
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        let countText  = item.count > 0 ? "\(item.count)" : ""
        let countLabel = NSTextField(labelWithString: countText)
        countLabel.font      = NSFont.systemFont(ofSize: 12)
        countLabel.textColor = NSColor.tertiaryLabelColor
        countLabel.alignment = .right
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.setContentHuggingPriority(.required,    for: .horizontal)
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(countLabel)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo:  icon.trailingAnchor, constant: 7),
            nameLabel.centerYAnchor.constraint(equalTo:  centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: countLabel.leadingAnchor, constant: -6),

            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            countLabel.centerYAnchor.constraint(equalTo:  centerYAnchor),
        ])
    }
}

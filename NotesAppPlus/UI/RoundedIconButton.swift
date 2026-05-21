import AppKit

final class RoundedIconButton: NSButton {
    private let diameter: CGFloat

    init(symbol: String, size: CGFloat = 34, iconPt: CGFloat = 15, tint: NSColor = .secondaryLabelColor, bg: Bool = true) {
        self.diameter = size
        super.init(frame: NSRect(x: 0, y: 0, width: size, height: size))

        let cfg = NSImage.SymbolConfiguration(pointSize: iconPt, weight: .regular)
        image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg)

        bezelStyle = .regularSquare
        isBordered = false
        imageScaling = .scaleProportionallyDown
        contentTintColor = tint
        wantsLayer = true
        layer?.cornerRadius = size / 2
        layer?.masksToBounds = true

        if bg {
            layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.06).cgColor
        }

        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: size).isActive = true
        heightAnchor.constraint(equalToConstant: size).isActive = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func updateLayer() {
        super.updateLayer()
        layer?.cornerRadius = diameter / 2
    }
}

import Foundation

// ISO 8601 formatter for database storage (UTC, fractional seconds).
enum ISO8601Format {
    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func string(from date: Date) -> String { formatter.string(from: date) }
    static func date(from string: String) -> Date? { formatter.date(from: string) }
}

// Human-readable dates for the notes list.
enum DateDisplay {
    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private static let absolute: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static func string(from date: Date) -> String {
        let age = Date().timeIntervalSince(date)
        return age < 86_400
            ? relative.localizedString(for: date, relativeTo: Date())
            : absolute.string(from: date)
    }
}

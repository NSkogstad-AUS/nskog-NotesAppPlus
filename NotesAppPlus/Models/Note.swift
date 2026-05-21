import Foundation

struct Note {
    let id: String
    var title: String
    let path: String
    let createdAt: Date
    var updatedAt: Date
    var preview: String
    var pinned: Bool

    // First non-empty line with markdown header markers stripped.
    static func extractTitle(from body: String) -> String {
        for line in body.components(separatedBy: .newlines) {
            var trimmed = line.trimmingCharacters(in: .whitespaces)
            while trimmed.hasPrefix("#") { trimmed = String(trimmed.dropFirst()) }
            trimmed = trimmed.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { return String(trimmed.prefix(100)) }
        }
        return "Untitled"
    }

    // Text from the second non-empty line onward, up to 200 characters.
    static func extractPreview(from body: String) -> String {
        var foundTitle = false
        var result = ""
        for line in body.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if !foundTitle { foundTitle = true; continue }
            if !result.isEmpty { result += " " }
            result += trimmed
            if result.count >= 200 { break }
        }
        return String(result.prefix(200))
    }
}

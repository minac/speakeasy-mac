import Foundation

enum TTSEngine: String, Codable, CaseIterable {
    case system
    case googleCloud

    var displayName: String {
        switch self {
        case .system: return "System (Free)"
        case .googleCloud: return "Google Cloud"
        }
    }
}

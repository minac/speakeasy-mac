import Foundation

// MARK: - String Extensions

extension String {
    /// Checks if the string is a valid URL (starts with http://, https://, or www.)
    var isValidURL: Bool {
        starts(with: "http://") || starts(with: "https://") || starts(with: "www.")
    }

    /// Adds HTTPS scheme if needed, returns nil if not a URL
    func addingHTTPSIfNeeded() -> String? {
        if starts(with: "http://") || starts(with: "https://") {
            return self
        } else if starts(with: "www.") {
            return "https://" + self
        }
        return nil
    }
}

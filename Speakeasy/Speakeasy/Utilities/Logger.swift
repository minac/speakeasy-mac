import OSLog

/// Structured logging utility using os.Logger
enum AppLogger {
    /// Logger for application state and lifecycle
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.speakeasy", category: "app")

    /// Logger for speech engine operations
    static let speech = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.speakeasy", category: "speech")

    /// Logger for text extraction and URL processing
    static let extraction = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.speakeasy", category: "extraction")

    /// Logger for keyboard shortcuts and permissions
    static let shortcuts = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.speakeasy", category: "shortcuts")

    /// Logger for settings and persistence
    static let settings = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.speakeasy", category: "settings")
}

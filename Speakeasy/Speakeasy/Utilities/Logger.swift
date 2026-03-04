import Foundation
import OSLog

public final class AppLogger: Sendable {
    public static let shared = AppLogger()

    private let osLog: Logger
    private let fileURL: URL
    private let queue = DispatchQueue(label: "app.logger.file", qos: .utility)
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = []
        return e
    }()

    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "app", category: String = "default") {
        self.osLog = Logger(subsystem: subsystem, category: category)
        #if os(iOS) || os(tvOS) || os(watchOS)
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        #else
        let base = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        #endif
        let logsDir = base.appendingPathComponent("logs")
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        self.fileURL = logsDir.appendingPathComponent("app.jsonl")
    }

    public func debug(_ msg: String, ctx: [String: String] = [:]) {
        osLog.debug("\(msg)")
        writeJSON(level: "debug", msg: msg, ctx: ctx)
    }

    public func info(_ msg: String, ctx: [String: String] = [:]) {
        osLog.info("\(msg)")
        writeJSON(level: "info", msg: msg, ctx: ctx)
    }

    public func warn(_ msg: String, ctx: [String: String] = [:]) {
        osLog.warning("\(msg)")
        writeJSON(level: "warn", msg: msg, ctx: ctx)
    }

    public func error(_ msg: String, ctx: [String: String] = [:]) {
        osLog.error("\(msg)")
        writeJSON(level: "error", msg: msg, ctx: ctx)
    }

    private struct LogEntry: Encodable {
        let ts: Date
        let level: String
        let msg: String
        let ctx: [String: String]?
    }

    private func writeJSON(level: String, msg: String, ctx: [String: String]) {
        let entry = LogEntry(ts: Date(), level: level, msg: msg, ctx: ctx.isEmpty ? nil : ctx)
        queue.async { [self] in
            guard let data = try? encoder.encode(entry),
                  let line = String(data: data, encoding: .utf8) else { return }
            let lineData = Data((line + "\n").utf8)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let handle = try? FileHandle(forWritingTo: fileURL) {
                    handle.seekToEndOfFile()
                    handle.write(lineData)
                    handle.closeFile()
                }
            } else {
                try? lineData.write(to: fileURL)
            }
        }
    }
}

public let log = AppLogger.shared

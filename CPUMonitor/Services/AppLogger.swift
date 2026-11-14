import Foundation
import AppKit
import os.log

/// Dedicated logger that records system diagnostics to both OSLog/Console and a persistent log file.
public final class AppLogger: @unchecked Sendable {
    public static let shared = AppLogger()
    
    private let osLogger = Logger(subsystem: "com.antigravity.cpumonitor", category: "Application")
    private let logFileURL: URL
    private let fileQueue = DispatchQueue(label: "com.antigravity.cpumonitor.logger", qos: .utility)
    private var fileHandle: FileHandle?
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return df
    }()
    
    public init() {
        var chosenURL: URL
        if let libraryLogs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Logs/CPUMonitor", isDirectory: true),
           (try? FileManager.default.createDirectory(at: libraryLogs, withIntermediateDirectories: true)) != nil {
            chosenURL = libraryLogs.appendingPathComponent("cpumonitor.log")
        } else {
            let tmpLogs = URL(fileURLWithPath: "/tmp", isDirectory: true).appendingPathComponent("cpumonitor.log")
            chosenURL = tmpLogs
        }
        
        self.logFileURL = chosenURL
        
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }
        
        self.fileHandle = try? FileHandle(forWritingTo: logFileURL)
        self.fileHandle?.seekToEndOfFile()
        
        log("=== CPU Monitor Session Started ===", level: .info)
        log("Log file path: \(logFileURL.path)", level: .info)
    }
    
    deinit {
        try? fileHandle?.close()
    }
    
    public enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
    }
    
    public func log(_ message: String, level: Level = .info) {
        let timestamp = dateFormatter.string(from: Date())
        let formattedMessage = "[\(timestamp)] [\(level.rawValue)] \(message)\n"
        
        // Output to standard error / stdout for terminal execution
        print("[\(level.rawValue)] \(message)")
        
        // Write to Apple Unified Logging system (Console.app)
        switch level {
        case .debug:
            osLogger.debug("\(message, privacy: .public)")
        case .info:
            osLogger.info("\(message, privacy: .public)")
        case .warning:
            osLogger.warning("\(message, privacy: .public)")
        case .error:
            osLogger.error("\(message, privacy: .public)")
        }
        
        // Write to persistent log file
        fileQueue.async { [weak self] in
            guard let self = self, let data = formattedMessage.data(using: .utf8) else { return }
            self.fileHandle?.write(data)
        }
    }
    
    public var currentLogPath: String {
        return logFileURL.path
    }
    
    public func openLogFile() {
        NSWorkspace.shared.selectFile(logFileURL.path, inFileViewerRootedAtPath: logFileURL.deletingLastPathComponent().path)
    }
}

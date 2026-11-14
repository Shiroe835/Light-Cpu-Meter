import Foundation
import Combine

/// Display presentation styles for the macOS menu bar indicator.
public enum MenuBarStyle: String, CaseIterable, Identifiable, Sendable {
    case text = "text"
    case square = "square"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .text:
            return "Percentage Text (CPU XX%)"
        case .square:
            return "Square Fill Meter"
        }
    }
}

/// Manages and persists the user's preferred menu bar display style.
@MainActor
public final class DisplayPreferences: ObservableObject {
    public static let shared = DisplayPreferences()
    
    private let key = "com.antigravity.cpumonitor.menuBarStyle"
    
    @Published public var style: MenuBarStyle {
        didSet {
            UserDefaults.standard.set(style.rawValue, forKey: key)
            AppLogger.shared.log("Display style changed to: \(style.rawValue)", level: .info)
        }
    }
    
    public init() {
        if let saved = UserDefaults.standard.string(forKey: key),
           let parsed = MenuBarStyle(rawValue: saved) {
            self.style = parsed
        } else {
            self.style = .text
        }
    }
    
    public func toggle() {
        style = (style == .text) ? .square : .text
    }
}

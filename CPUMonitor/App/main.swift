import AppKit

MainActor.assumeIsolated {
    AppLogger.shared.log("main.swift: Initializing CPU Monitor application", level: .info)
    
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    
    AppLogger.shared.log("main.swift: Starting NSApplication event run loop", level: .info)
    app.run()
}

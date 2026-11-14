import AppKit
import SwiftUI
import Combine

/// Application Delegate managing the menu bar NSStatusItem, NSPopover, display styles, and lifecycle.
@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover = NSPopover()
    
    private let engine = CPUMonitorEngine()
    private let launchManager = LaunchAtLoginManager()
    private let displayPreferences = DisplayPreferences.shared
    private var cancellables = Set<AnyCancellable>()
    private var sampleCount: Int = 0
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.shared.log("applicationDidFinishLaunching called", level: .info)
        
        // Ensure menu-bar-only accessory policy (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        setupPopover()
        bindEngineMetrics()
        bindDisplayPreferences()
        
        // Start CPU monitoring
        AppLogger.shared.log("Starting CPUMonitorEngine", level: .info)
        engine.startMonitoring()
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        AppLogger.shared.log("applicationWillTerminate called", level: .info)
        engine.stopMonitoring()
    }
    
    // MARK: - Menu Bar Setup
    
    private func setupStatusItem() {
        AppLogger.shared.log("Creating system status item...", level: .info)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.isVisible = true
        
        guard let button = statusItem?.button else {
            AppLogger.shared.log("Failed to obtain NSStatusBarButton from NSStatusItem", level: .error)
            return
        }
        
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.setAccessibilityLabel("CPU Monitor")
        button.appearsDisabled = false
        
        updateStatusBar(with: engine.metrics)
        AppLogger.shared.log("Status item button configured successfully", level: .info)
    }
    
    private func setupPopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        
        let dropdownView = DropdownView(
            engine: engine,
            launchManager: launchManager,
            displayPreferences: displayPreferences
        )
        let hostingController = NSHostingController(rootView: dropdownView)
        popover.contentViewController = hostingController
        AppLogger.shared.log("NSPopover configured with DropdownView", level: .info)
    }
    
    private func bindEngineMetrics() {
        engine.$metrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.updateStatusBar(with: metrics)
            }
            .store(in: &cancellables)
    }
    
    private func bindDisplayPreferences() {
        displayPreferences.$style
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateStatusBar(with: self.engine.metrics)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Status Bar Presentation
    
    private func updateStatusBar(with metrics: CPUMetrics) {
        guard let button = statusItem?.button else { return }
        let totalUsage = metrics.totalUsage
        let percentageInt = Int(totalUsage.rounded())
        
        button.toolTip = "CPU Usage: \(percentageInt)%"
        button.setAccessibilityValue("\(percentageInt) percent")
        
        switch displayPreferences.style {
        case .text:
            button.image = nil
            button.title = "CPU \(percentageInt)%"
            button.imagePosition = .noImage
        case .square:
            button.title = ""
            button.image = createSquareIcon(percentage: totalUsage)
            button.imagePosition = .imageOnly
        }
        
        sampleCount += 1
        if sampleCount <= 3 || sampleCount % 30 == 0 {
            AppLogger.shared.log(
                "Updated menu bar indicator: style=\(displayPreferences.style.rawValue) value=\(percentageInt)% (Total: \(String(format: "%.1f", totalUsage))%)",
                level: .debug
            )
        }
    }
    
    /// Generates a crisp, resolution-independent square icon that fills vertically based on CPU load.
    /// Green fill until 90%, red fill above 90% usage.
    private func createSquareIcon(percentage: Double) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: false) { rect in
            let outerRect = NSRect(x: 2.0, y: 2.0, width: 14.0, height: 14.0)
            let cornerRadius: CGFloat = 2.5
            let path = NSBezierPath(roundedRect: outerRect, xRadius: cornerRadius, yRadius: cornerRadius)
            
            // Subtle translucent background for unfilled capacity
            NSColor.labelColor.withAlphaComponent(0.12).setFill()
            path.fill()
            
            // Clip inner region to draw the dynamic fill
            NSGraphicsContext.saveGraphicsState()
            path.addClip()
            
            let clampedPct = min(max(percentage, 0.0), 100.0)
            let fillHeight = CGFloat(clampedPct / 100.0) * outerRect.height
            let fillRect = NSRect(
                x: outerRect.minX,
                y: outerRect.minY,
                width: outerRect.width,
                height: fillHeight
            )
            
            // Color rule: Green fill until 90%, red fill above 90%
            let fillColor: NSColor = clampedPct > 90.0 ? .systemRed : .systemGreen
            fillColor.setFill()
            fillRect.fill()
            
            NSGraphicsContext.restoreGraphicsState()
            
            // Outer border stroke
            let strokeColor = NSColor.labelColor.withAlphaComponent(0.4)
            strokeColor.setStroke()
            path.lineWidth = 1.0
            path.stroke()
            
            return true
        }
        
        // Keep template false so native green and red colors render accurately
        img.isTemplate = false
        return img
    }
    
    // MARK: - Actions
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let currentEvent = NSApp.currentEvent
        
        // Right click opens contextual menu
        if currentEvent?.type == .rightMouseUp {
            AppLogger.shared.log("Status item right-clicked: presenting context menu", level: .debug)
            showContextMenu(from: sender)
            return
        }
        
        // Left click toggles the compact dropdown popover
        togglePopover(sender)
    }
    
    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            AppLogger.shared.log("Closing popover", level: .debug)
            popover.performClose(sender)
        } else {
            AppLogger.shared.log("Opening popover", level: .debug)
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    private func showContextMenu(from button: NSStatusBarButton) {
        let menu = NSMenu()
        
        // Quick toggle item
        let toggleTitle = (displayPreferences.style == .text)
            ? "Switch to Square Fill Meter"
            : "Switch to Percentage Text"
        let quickToggleItem = NSMenuItem(
            title: toggleTitle,
            action: #selector(toggleDisplayStyle),
            keyEquivalent: ""
        )
        quickToggleItem.target = self
        menu.addItem(quickToggleItem)
        
        // Submenu with explicit selection options
        let styleSubmenu = NSMenu()
        
        let textModeItem = NSMenuItem(
            title: "Percentage Text (CPU XX%)",
            action: #selector(setDisplayStyleText),
            keyEquivalent: ""
        )
        textModeItem.target = self
        textModeItem.state = (displayPreferences.style == .text) ? .on : .off
        styleSubmenu.addItem(textModeItem)
        
        let squareModeItem = NSMenuItem(
            title: "Square Fill Meter (Green ≤ 90%, Red > 90%)",
            action: #selector(setDisplayStyleSquare),
            keyEquivalent: ""
        )
        squareModeItem.target = self
        squareModeItem.state = (displayPreferences.style == .square) ? .on : .off
        styleSubmenu.addItem(squareModeItem)
        
        let styleParentItem = NSMenuItem(title: "Display Style", action: nil, keyEquivalent: "")
        styleParentItem.submenu = styleSubmenu
        menu.addItem(styleParentItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.state = launchManager.isEnabled ? .on : .off
        launchItem.target = self
        menu.addItem(launchItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let activityMonitorItem = NSMenuItem(
            title: "Open Activity Monitor",
            action: #selector(openActivityMonitorMenuAction),
            keyEquivalent: ""
        )
        activityMonitorItem.target = self
        menu.addItem(activityMonitorItem)
        
        let viewLogsItem = NSMenuItem(
            title: "View Diagnostics Log",
            action: #selector(openLogAction),
            keyEquivalent: ""
        )
        viewLogsItem.target = self
        menu.addItem(viewLogsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit CPU Monitor",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil // Clear menu so subsequent left-clicks toggle popover
    }
    
    @objc private func toggleDisplayStyle() {
        displayPreferences.toggle()
    }
    
    @objc private func setDisplayStyleText() {
        displayPreferences.style = .text
    }
    
    @objc private func setDisplayStyleSquare() {
        displayPreferences.style = .square
    }
    
    @objc private func toggleLaunchAtLogin() {
        launchManager.setEnabled(!launchManager.isEnabled)
    }
    
    @objc private func openActivityMonitorMenuAction() {
        let appUrl = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.open(appUrl)
    }
    
    @objc private func openLogAction() {
        AppLogger.shared.openLogFile()
    }
    
    @objc private func quitApp() {
        AppLogger.shared.log("Quit requested by user", level: .info)
        NSApplication.shared.terminate(nil)
    }
}

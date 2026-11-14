import SwiftUI
import AppKit

/// Main dropdown view presented when clicking the menu bar CPU indicator.
public struct DropdownView: View {
    @ObservedObject public var engine: CPUMonitorEngine
    @ObservedObject public var launchManager: LaunchAtLoginManager
    @ObservedObject public var displayPreferences: DisplayPreferences
    
    public init(
        engine: CPUMonitorEngine,
        launchManager: LaunchAtLoginManager,
        displayPreferences: DisplayPreferences = DisplayPreferences.shared
    ) {
        self.engine = engine
        self.launchManager = launchManager
        self.displayPreferences = displayPreferences
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Bar
            HStack(alignment: .center) {
                Image(systemName: "cpu")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
                
                Text("CPU Monitor")
                    .font(.system(size: 13, weight: .semibold))
                
                Spacer()
                
                // Live indicator badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(4)
            }
            
            Divider()
            
            // Section 1: CPU Overview
            CPUOverviewSection(
                metrics: engine.metrics,
                logicalCores: engine.systemInfo.logicalCores
            )
            
            // Section 2: Per-Core Monitoring
            if !engine.metrics.cores.isEmpty {
                PerCoreSection(cores: engine.metrics.cores)
            }
            
            // Section 3: System Information
            SystemInfoSection(systemInfo: engine.systemInfo)
            
            Divider()
            
            // Section 4: Display Mode & Controls
            VStack(spacing: 10) {
                // Menu Bar Display Style Picker
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Menu Bar Appearance")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Picker("Display Mode", selection: $displayPreferences.style) {
                        Text("Percentage Text").tag(MenuBarStyle.text)
                        Text("Square Fill Meter").tag(MenuBarStyle.square)
                    }
                    .pickerStyle(.segmented)
                }
                
                // Launch at Login Toggle
                Toggle(isOn: Binding(
                    get: { launchManager.isEnabled },
                    set: { launchManager.setEnabled($0) }
                )) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("Launch at Login")
                            .font(.system(size: 11, weight: .regular))
                    }
                }
                .toggleStyle(.checkbox)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let error = launchManager.errorMessage {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
                
                HStack(spacing: 6) {
                    // Open Activity Monitor
                    Button(action: openActivityMonitor) {
                        HStack(spacing: 3) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 10))
                            Text("Activity Monitor")
                                .font(.system(size: 10))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    // View Logs Button
                    Button(action: openLogs) {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 10))
                            Text("Logs")
                                .font(.system(size: 10))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    // Quit Button
                    Button(action: quitApp) {
                        HStack(spacing: 3) {
                            Image(systemName: "power")
                                .font(.system(size: 10))
                            Text("Quit")
                                .font(.system(size: 10))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(14)
        .frame(width: 320)
    }
    
    private func openActivityMonitor() {
        let appUrl = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.open(appUrl)
    }
    
    private func openLogs() {
        AppLogger.shared.openLogFile()
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

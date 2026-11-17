# CPU Monitor for macOS (Intel & Universal)

A lightweight, high-performance, native macOS menu bar utility that provides real-time CPU usage monitoring directly in the macOS menu bar. Specifically engineered and optimized for Intel-based MacBooks (x86_64) as well as Apple Silicon (Universal Binary).

Designed to look and behave like a first-party macOS utility, CPU Monitor provides continuous visibility into processor load without needing to open Activity Monitor.

---

## Key Features

- **Dual Menu Bar Display Modes**:
  - **Text Mode**: Displays total CPU usage as clean percentage text (e.g. `CPU 12%`) with monospaced digits.
  - **Square Fill Meter**: Displays a compact 14×14pt square icon in the menu bar that fills from bottom to top proportionally to CPU utilization:
    - **Green fill** for usage $\le 90\%$.
    - **Red fill** for usage $> 90\%$.
- **Right-Click Switching**: Right-click the menu bar item at any time to instantly switch between the Percentage Text and the Square Fill Meter.
- **Pure Native Utility**: Built exclusively in Swift with AppKit and SwiftUI. Zero Electron, zero Python runtimes, zero web views, zero external dependencies.
- **Detailed Dropdown Interface (Left-Click)**:
  - **CPU Overview**: Total utilization gauge, breakdown of User, System, and Idle percentages, plus active logical core count.
  - **Per-Core Monitoring**: Individual horizontal progress bars and percentages for every logical CPU core.
  - **System Information**: Exact CPU model name (e.g., `Intel(R) Core(TM) i5-8210Y CPU @ 1.60GHz`), architecture, and physical vs. logical core counts.
  - **Display Style Selector**: Easily switch between Text and Square Meter directly in the dropdown.
  - **Quick Controls**: One-click "Launch at Login" toggle, "Activity Monitor" shortcut, "Logs" viewer button, and Quit button.
- **Automatic Theme Support**: Seamlessly adapts to macOS Light and Dark appearances using dynamic system colors.
- **Menu Bar Only (No Dock Icon)**: Configured with `LSUIElement = true` and `.accessory` activation policy to stay completely hidden from the macOS Dock and App Switcher (`⌘Tab`).
- **Sleep & Wake Resilient**: Listens to `NSWorkspace.willSleepNotification` and `NSWorkspace.didWakeNotification` to reset tick baselines, preventing erroneous CPU spikes or calculations after sleep.
- **Leak-Free Mach Sampling**: Rigorously releases kernel virtual memory buffers via `vm_deallocate` after each sample.
- **Diagnostic Logging**: Comprehensive system logging to Console (`os.Logger`), persistent file logging, and standard output.

---

## Right-Click Menu Options

Right-clicking the menu bar icon brings up the contextual control menu:
- **Switch to Square Fill Meter / Switch to Percentage Text**: 1-click toggle between display modes.
- **Display Style Submenu**: Explicit selection with checkmarks (`✓`):
  - `Percentage Text (CPU XX%)`
  - `Square Fill Meter (Green ≤ 90%, Red > 90%)`
- **Launch at Login**: Toggle automatic startup.
- **Open Activity Monitor**: Quick launch shortcut.
- **View Diagnostics Log**: Opens the active log file in Finder.
- **Quit CPU Monitor**: Cleanly terminates the application (`⌘Q`).

---

## Architecture & Technology Stack

| Component | Implementation |
|---|---|
| **Language** | Swift 6 / 5.0 |
| **Frameworks** | SwiftUI + AppKit |
| **CPU Monitoring** | Mach Kernel APIs (`host_processor_info`, `PROCESSOR_CPU_LOAD_INFO`) |
| **System Info** | BSD `sysctlbyname` (`machdep.cpu.brand_string`, `hw.physicalcpu`, `hw.logicalcpu`) |
| **Menu Bar Integration** | `NSStatusItem` + `NSPopover` hosting SwiftUI `DropdownView` |
| **Auto-Startup** | ServiceManagement framework (`SMAppService.mainApp`) |
| **Preferences** | `DisplayPreferences` backed by `UserDefaults` |
| **Diagnostics & Logs** | Unified Apple Logging (`os.Logger`) + Persistent File Logging |
| **Target Architecture** | x86_64 (Intel 64-bit) & arm64 (Universal Binary) |
| **Minimum OS** | macOS 13.0 Ventura or later (tested on macOS 14 Sonoma) |

---

## Project Structure

```
Activity bar/
├── CPUMonitor/
│   ├── App/
│   │   ├── main.swift                 # Pure AppKit entry point with MainActor.assumeIsolated
│   │   ├── AppDelegate.swift          # Status item, square icon rendering, context menu
│   │   └── LaunchAtLoginManager.swift # SMAppService auto-launch integration
│   ├── Models/
│   │   ├── CPUMetrics.swift           # CoreUsage, CPUMetrics, and SystemInfo models
│   │   └── DisplayPreferences.swift   # Text vs. Square Meter preference management
│   ├── Services/
│   │   ├── AppLogger.swift            # OSLog + persistent file diagnostics logger
│   │   ├── CPUMonitorEngine.swift     # Mach kernel CPU sampling, tick delta math, vm_deallocate
│   │   └── SystemInfoService.swift    # Low-level sysctl hardware info querying
│   ├── Views/
│   │   ├── DropdownView.swift         # Main popover interface container
│   │   ├── CPUOverviewSection.swift   # Total, user, system, idle meters and breakdown
│   │   ├── PerCoreSection.swift       # Horizontal progress bars for individual cores
│   │   └── SystemInfoSection.swift    # CPU brand, architecture, core counts display
│   └── Resources/
│       ├── Info.plist                 # LSUIElement = YES (no Dock icon)
│       └── CPUMonitor.entitlements    # Application entitlements
├── CPUMonitor.xcodeproj/              # Complete Xcode project
├── Scripts/
│   ├── build.sh                       # Automates compilation of Release .app
├── build/
│   └── Release/
│       └── CPUMonitor.app             # Compiled application bundle
├── CPUMonitor.app                     # Ready-to-run application bundle in root
└── README.md                          # Documentation and instructions
```

---

## Build and Installation Instructions

### Run the Application Directly
```bash
open "CPUMonitor.app"
```

### Install to `/Applications`
```bash
/bin/bash Scripts/install.sh
```

### Rebuild from Source
```bash
/bin/bash Scripts/build.sh
```

---

## License

MIT License. Designed and developed as a clean, native macOS utility.

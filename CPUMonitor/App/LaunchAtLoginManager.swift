import Foundation
import ServiceManagement

/// Manages macOS launch-at-login registration using SMAppService (macOS 13+).
@MainActor
public final class LaunchAtLoginManager: ObservableObject {
    @Published public private(set) var isEnabled: Bool = false
    @Published public var errorMessage: String? = nil
    
    public init() {
        refreshStatus()
    }
    
    /// Checks the current registration state with macOS system service management.
    public func refreshStatus() {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            self.isEnabled = (status == .enabled)
        } else {
            self.isEnabled = false
        }
    }
    
    /// Toggles the auto-launch state.
    public func setEnabled(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
            refreshStatus()
        }
    }
}

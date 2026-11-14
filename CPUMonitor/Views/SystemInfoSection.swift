import SwiftUI

/// Section displaying hardware specifications: CPU model, architecture, and core breakdown.
public struct SystemInfoSection: View {
    public let systemInfo: SystemInfo
    
    public init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SYSTEM INFORMATION")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            
            VStack(spacing: 5) {
                InfoRow(label: "Processor", value: systemInfo.cpuModel)
                InfoRow(label: "Architecture", value: systemInfo.architecture)
                InfoRow(
                    label: "Cores",
                    value: "\(systemInfo.physicalCores) Physical / \(systemInfo.logicalCores) Logical"
                )
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .cornerRadius(8)
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
}

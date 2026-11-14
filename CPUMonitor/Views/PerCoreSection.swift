import SwiftUI

/// Section displaying individual utilization for each CPU core with horizontal progress bars.
public struct PerCoreSection: View {
    public let cores: [CoreUsage]
    
    public init(cores: [CoreUsage]) {
        self.cores = cores
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("PER-CORE USAGE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(cores.count) Cores Active")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            // Core Bars
            VStack(spacing: 6) {
                ForEach(cores) { core in
                    CoreRowView(core: core)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .cornerRadius(8)
        }
    }
}

/// Single core horizontal progress bar row.
private struct CoreRowView: View {
    let core: CoreUsage
    
    var body: some View {
        HStack(spacing: 8) {
            // Core identifier
            Text("Core \(core.id + 1)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 48, alignment: .leading)
            
            // Horizontal progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 6)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(for: core.totalUsage))
                        .frame(
                            width: max(0, min(geo.size.width, geo.size.width * CGFloat(core.totalUsage / 100.0))),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
            
            // Value percentage
            Text(String(format: "%5.1f%%", core.totalUsage))
                .font(.system(size: 11, weight: .regular))
                .monospacedDigit()
                .foregroundColor(.primary)
                .frame(width: 46, alignment: .trailing)
        }
    }
    
    private func barColor(for usage: Double) -> Color {
        if usage < 50.0 {
            return .accentColor
        } else if usage < 80.0 {
            return .orange
        } else {
            return .red
        }
    }
}

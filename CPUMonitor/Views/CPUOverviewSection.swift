import SwiftUI

/// Displays overall CPU utilization metrics (Total, User, System, Idle) and core count.
public struct CPUOverviewSection: View {
    public let metrics: CPUMetrics
    public let logicalCores: Int
    
    public init(metrics: CPUMetrics, logicalCores: Int) {
        self.metrics = metrics
        self.logicalCores = logicalCores
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("CPU OVERVIEW")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(logicalCores) Logical Cores")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            // Total Usage Highlight Box
            HStack(spacing: 14) {
                // Circular mini gauge or ring
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 5)
                        .frame(width: 46, height: 46)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(metrics.totalUsage / 100.0))
                        .stroke(
                            gaugeColor(for: metrics.totalUsage),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 46, height: 46)
                    
                    Text("\(Int(metrics.totalUsage.rounded()))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Total Utilization")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text(String(format: "%.1f%%", metrics.totalUsage))
                            .font(.system(size: 13, weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(gaugeColor(for: metrics.totalUsage))
                    }
                    
                    // Segmented usage bar
                    GeometryReader { geo in
                        HStack(spacing: 1) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.blue)
                                .frame(width: max(0, geo.size.width * CGFloat(metrics.userUsage / 100.0)))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.orange)
                                .frame(width: max(0, geo.size.width * CGFloat(metrics.systemUsage / 100.0)))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: max(0, geo.size.width * CGFloat(metrics.idleUsage / 100.0)))
                        }
                    }
                    .frame(height: 5)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .cornerRadius(8)
            
            // Breakdown Stats Grid
            HStack(spacing: 8) {
                StatPill(
                    title: "User",
                    value: String(format: "%.1f%%", metrics.userUsage),
                    dotColor: .blue
                )
                
                StatPill(
                    title: "System",
                    value: String(format: "%.1f%%", metrics.systemUsage),
                    dotColor: .orange
                )
                
                StatPill(
                    title: "Idle",
                    value: String(format: "%.1f%%", metrics.idleUsage),
                    dotColor: .green
                )
            }
        }
    }
    
    private func gaugeColor(for value: Double) -> Color {
        if value < 55.0 {
            return .blue
        } else if value < 80.0 {
            return .orange
        } else {
            return .red
        }
    }
}

/// Compact stat display box for individual CPU categories.
private struct StatPill: View {
    let title: String
    let value: String
    let dotColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .cornerRadius(6)
    }
}

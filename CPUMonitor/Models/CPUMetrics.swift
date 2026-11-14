import Foundation

/// Represents CPU metrics for an individual processor core.
public struct CoreUsage: Identifiable, Sendable, Equatable {
    public let id: Int
    public let userPercentage: Double
    public let systemPercentage: Double
    public let idlePercentage: Double
    public let nicePercentage: Double
    
    /// Total active CPU usage for this core (User + System + Nice), clamped to 0.0 - 100.0.
    public var totalUsage: Double {
        let active = userPercentage + systemPercentage + nicePercentage
        return min(max(active, 0.0), 100.0)
    }
    
    public init(id: Int, userPercentage: Double, systemPercentage: Double, idlePercentage: Double, nicePercentage: Double) {
        self.id = id
        self.userPercentage = userPercentage
        self.systemPercentage = systemPercentage
        self.idlePercentage = idlePercentage
        self.nicePercentage = nicePercentage
    }
}

/// Represents the overall system CPU metrics sampled over an interval.
public struct CPUMetrics: Sendable, Equatable {
    public let totalUsage: Double
    public let userUsage: Double
    public let systemUsage: Double
    public let idleUsage: Double
    public let niceUsage: Double
    public let cores: [CoreUsage]
    public let timestamp: Date
    
    public static let zero = CPUMetrics(
        totalUsage: 0.0,
        userUsage: 0.0,
        systemUsage: 0.0,
        idleUsage: 100.0,
        niceUsage: 0.0,
        cores: [],
        timestamp: Date()
    )
    
    public init(
        totalUsage: Double,
        userUsage: Double,
        systemUsage: Double,
        idleUsage: Double,
        niceUsage: Double,
        cores: [CoreUsage],
        timestamp: Date = Date()
    ) {
        self.totalUsage = min(max(totalUsage, 0.0), 100.0)
        self.userUsage = min(max(userUsage, 0.0), 100.0)
        self.systemUsage = min(max(systemUsage, 0.0), 100.0)
        self.idleUsage = min(max(idleUsage, 0.0), 100.0)
        self.niceUsage = min(max(niceUsage, 0.0), 100.0)
        self.cores = cores
        self.timestamp = timestamp
    }
}

/// Hardware and architecture system details.
public struct SystemInfo: Sendable, Equatable {
    public let cpuModel: String
    public let architecture: String
    public let physicalCores: Int
    public let logicalCores: Int
    
    public init(cpuModel: String, architecture: String, physicalCores: Int, logicalCores: Int) {
        self.cpuModel = cpuModel
        self.architecture = architecture
        self.physicalCores = physicalCores
        self.logicalCores = logicalCores
    }
}

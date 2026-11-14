import Foundation
import Darwin

/// Service that queries hardware and CPU architecture information using low-level sysctl APIs.
public final class SystemInfoService: @unchecked Sendable {
    public static let shared = SystemInfoService()
    
    public let systemInfo: SystemInfo
    
    public init() {
        let model = Self.queryCPUModel()
        let arch = Self.queryArchitecture()
        let physical = Self.queryPhysicalCores()
        let logical = Self.queryLogicalCores()
        
        self.systemInfo = SystemInfo(
            cpuModel: model,
            architecture: arch,
            physicalCores: physical,
            logicalCores: logical
        )
    }
    
    /// Queries the CPU brand string (e.g., "Intel(R) Core(TM) i5-8210Y CPU @ 1.60GHz").
    private static func queryCPUModel() -> String {
        var size: Int = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        guard size > 0 else {
            return "Intel Core Processor"
        }
        var buffer = [CChar](repeating: 0, count: size)
        if sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0) == 0 {
            let str = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
            if !str.isEmpty {
                return str
            }
        }
        return "Intel Core Processor"
    }
    
    /// Identifies the CPU architecture, specifically identifying Intel x86_64.
    private static func queryArchitecture() -> String {
        #if arch(x86_64)
        return "Intel (x86_64)"
        #elseif arch(arm64)
        return "Apple Silicon (arm64)"
        #else
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        return machine
        #endif
    }
    
    /// Queries the number of physical CPU cores via `hw.physicalcpu`.
    private static func queryPhysicalCores() -> Int {
        var physical: Int32 = 0
        var size = MemoryLayout<Int32>.size
        if sysctlbyname("hw.physicalcpu", &physical, &size, nil, 0) == 0 && physical > 0 {
            return Int(physical)
        }
        return 1
    }
    
    /// Queries the number of logical CPU cores (threads) via `hw.logicalcpu`.
    private static func queryLogicalCores() -> Int {
        var logical: Int32 = 0
        var size = MemoryLayout<Int32>.size
        if sysctlbyname("hw.logicalcpu", &logical, &size, nil, 0) == 0 && logical > 0 {
            return Int(logical)
        }
        return ProcessInfo.processInfo.processorCount
    }
}

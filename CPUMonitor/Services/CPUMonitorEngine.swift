import Foundation
import AppKit
import Darwin

/// CPU core tick measurement snapshot.
private struct CoreTicks: Sendable {
    let user: UInt32
    let system: UInt32
    let idle: UInt32
    let nice: UInt32
}

/// Real-time CPU monitoring engine leveraging macOS Mach kernel APIs.
/// Samples CPU load per-core and calculates delta utilization every second.
@MainActor
public final class CPUMonitorEngine: ObservableObject {
    @Published public private(set) var metrics: CPUMetrics = .zero
    @Published public private(set) var isMonitoring: Bool = false
    
    public let systemInfo: SystemInfo
    
    private var timer: Timer?
    private var previousCoreTicks: [CoreTicks]?
    private var needsBaselineReset: Bool = true
    private let sampleQueue = DispatchQueue(label: "com.antigravity.cpumonitor.sampler", qos: .utility)
    
    public init(systemInfo: SystemInfo = SystemInfoService.shared.systemInfo) {
        self.systemInfo = systemInfo
        setupSleepWakeObservers()
    }
    
    deinit {
        timer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    // MARK: - Lifecycle Management
    
    /// Starts real-time CPU sampling at 1-second intervals.
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        needsBaselineReset = true
        previousCoreTicks = nil
        
        // Take immediate initial sample to establish baseline
        sampleQueue.async {
            let initialTicks = Self.fetchRawTicks()
            Task { @MainActor [weak self] in
                guard let self = self, self.isMonitoring else { return }
                self.previousCoreTicks = initialTicks
                self.needsBaselineReset = false
            }
        }
        
        // Short delay (250ms) to produce an immediate initial reading, then standard 1.0s interval
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self, self.isMonitoring else { return }
            self.sampleOnce()
            self.scheduleTimer()
        }
    }
    
    /// Stops the sampling timer.
    public func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        previousCoreTicks = nil
        needsBaselineReset = true
    }
    
    private func scheduleTimer() {
        timer?.invalidate()
        let t = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(timerFired),
            userInfo: nil,
            repeats: true
        )
        self.timer = t
        RunLoop.main.add(t, forMode: .common)
    }
    
    @objc private func timerFired() {
        sampleOnce()
    }
    
    // MARK: - Sleep & Wake Handling
    
    private func setupSleepWakeObservers() {
        let center = NSWorkspace.shared.notificationCenter
        
        center.addObserver(
            self,
            selector: #selector(handleWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        center.addObserver(
            self,
            selector: #selector(handleDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    @objc private func handleWillSleep() {
        // Invalidate timer and clear ticks to prevent abnormal delta on wake
        timer?.invalidate()
        timer = nil
        previousCoreTicks = nil
        needsBaselineReset = true
    }
    
    @objc private func handleDidWake() {
        needsBaselineReset = true
        guard isMonitoring else { return }
        
        sampleQueue.async {
            let ticks = Self.fetchRawTicks()
            Task { @MainActor [weak self] in
                guard let self = self, self.isMonitoring else { return }
                self.previousCoreTicks = ticks
                self.needsBaselineReset = false
                self.scheduleTimer()
            }
        }
    }
    
    // MARK: - Sampling Implementation
    
    private func sampleOnce() {
        sampleQueue.async {
            let currentTicks = Self.fetchRawTicks()
            Task { @MainActor [weak self] in
                guard let self = self, self.isMonitoring else { return }
                guard let currentTicks = currentTicks, !currentTicks.isEmpty else { return }
                
                if self.needsBaselineReset || self.previousCoreTicks == nil || self.previousCoreTicks?.count != currentTicks.count {
                    self.previousCoreTicks = currentTicks
                    self.needsBaselineReset = false
                    return
                }
                
                guard let prevTicks = self.previousCoreTicks else { return }
                self.previousCoreTicks = currentTicks
                self.metrics = self.calculateMetrics(current: currentTicks, previous: prevTicks)
            }
        }
    }
    
    /// Queries the Mach kernel for per-processor CPU load info.
    /// Memory allocated by `host_processor_info` is strictly deallocated via `vm_deallocate`.
    private nonisolated static func fetchRawTicks() -> [CoreTicks]? {
        var numProcessors: natural_t = 0
        var processorInfo: processor_info_array_t?
        var count: mach_msg_type_number_t = 0
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numProcessors,
            &processorInfo,
            &count
        )
        
        guard result == KERN_SUCCESS, let info = processorInfo else {
            return nil
        }
        
        // Guarantee deallocation of Mach virtual memory buffer to prevent leaks
        defer {
            let bufferSize = vm_size_t(count * UInt32(MemoryLayout<integer_t>.size))
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: info)), bufferSize)
        }
        
        let cpuLoadInfo = info.withMemoryRebound(to: processor_cpu_load_info.self, capacity: Int(numProcessors)) {
            Array(UnsafeBufferPointer(start: $0, count: Int(numProcessors)))
        }
        
        return cpuLoadInfo.map { core in
            CoreTicks(
                user: UInt32(core.cpu_ticks.0),
                system: UInt32(core.cpu_ticks.1),
                idle: UInt32(core.cpu_ticks.2),
                nice: UInt32(core.cpu_ticks.3)
            )
        }
    }
    
    /// Calculates usage percentages from consecutive samples handling UInt32 wraparound.
    private func calculateMetrics(current: [CoreTicks], previous: [CoreTicks]) -> CPUMetrics {
        var coreUsages: [CoreUsage] = []
        var sumUserTicks: UInt64 = 0
        var sumSystemTicks: UInt64 = 0
        var sumIdleTicks: UInt64 = 0
        var sumNiceTicks: UInt64 = 0
        
        for i in 0..<current.count {
            let curr = current[i]
            let prev = previous[i]
            
            let dUser = deltaTick(curr.user, prev.user)
            let dSystem = deltaTick(curr.system, prev.system)
            let dIdle = deltaTick(curr.idle, prev.idle)
            let dNice = deltaTick(curr.nice, prev.nice)
            
            let coreTotalTicks = Double(dUser + dSystem + dIdle + dNice)
            
            let uPct: Double
            let sPct: Double
            let iPct: Double
            let nPct: Double
            
            if coreTotalTicks > 0 {
                uPct = (Double(dUser) / coreTotalTicks) * 100.0
                sPct = (Double(dSystem) / coreTotalTicks) * 100.0
                iPct = (Double(dIdle) / coreTotalTicks) * 100.0
                nPct = (Double(dNice) / coreTotalTicks) * 100.0
            } else {
                uPct = 0.0
                sPct = 0.0
                iPct = 100.0
                nPct = 0.0
            }
            
            coreUsages.append(
                CoreUsage(
                    id: i,
                    userPercentage: uPct,
                    systemPercentage: sPct,
                    idlePercentage: iPct,
                    nicePercentage: nPct
                )
            )
            
            sumUserTicks += dUser
            sumSystemTicks += dSystem
            sumIdleTicks += dIdle
            sumNiceTicks += dNice
        }
        
        let grandTotalTicks = Double(sumUserTicks + sumSystemTicks + sumIdleTicks + sumNiceTicks)
        let totalUser: Double
        let totalSystem: Double
        let totalIdle: Double
        let totalNice: Double
        let totalActive: Double
        
        if grandTotalTicks > 0 {
            totalUser = (Double(sumUserTicks) / grandTotalTicks) * 100.0
            totalSystem = (Double(sumSystemTicks) / grandTotalTicks) * 100.0
            totalIdle = (Double(sumIdleTicks) / grandTotalTicks) * 100.0
            totalNice = (Double(sumNiceTicks) / grandTotalTicks) * 100.0
            totalActive = (Double(sumUserTicks + sumSystemTicks + sumNiceTicks) / grandTotalTicks) * 100.0
        } else {
            totalUser = 0.0
            totalSystem = 0.0
            totalIdle = 100.0
            totalNice = 0.0
            totalActive = 0.0
        }
        
        return CPUMetrics(
            totalUsage: totalActive,
            userUsage: totalUser,
            systemUsage: totalSystem,
            idleUsage: totalIdle,
            niceUsage: totalNice,
            cores: coreUsages,
            timestamp: Date()
        )
    }
    
    /// Computes delta ticks with 32-bit integer overflow protection.
    private func deltaTick(_ current: UInt32, _ previous: UInt32) -> UInt64 {
        if current >= previous {
            return UInt64(current - previous)
        } else {
            // UInt32 wraparound overflow
            return (UInt64(UInt32.max) - UInt64(previous)) + UInt64(current) + 1
        }
    }
}

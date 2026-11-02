// Linux stand-ins for the Apple frameworks the client's protocol layer imports (Metal, VideoToolbox, Combine, AVKit,
// Network, UIKit, QuartzCore, simd). Only the surface ALVRClient/EventHandler.swift touches exists here; everything is
// inert except what the harness needs to observe (the decoder session object, the app state, the clock).
//
// Each framework name is a one-line module that re-exports this one (see build.sh), so the client's own `import
// VideoToolbox` etc. compile unchanged.

import Foundation
@_exported import CAlvr

// MARK: - QuartzCore

public func CACurrentMediaTime() -> Double {
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return Double(ts.tv_sec) + Double(ts.tv_nsec) / 1e9
}

public let MSEC_PER_SEC: UInt64 = 1000
public let NSEC_PER_SEC: UInt64 = 1_000_000_000

// MARK: - objc runtime (objc_sync_enter / exit), recursive per object like the real one

private let syncTableLock = NSLock()
nonisolated(unsafe) private var syncTable: [ObjectIdentifier: NSRecursiveLock] = [:]

private func syncLock(_ obj: AnyObject) -> NSRecursiveLock {
    syncTableLock.lock()
    defer { syncTableLock.unlock() }
    let id = ObjectIdentifier(obj)
    if let l = syncTable[id] { return l }
    let l = NSRecursiveLock()
    syncTable[id] = l
    return l
}

@discardableResult public func objc_sync_enter(_ obj: Any) -> Int32 {
    syncLock(obj as AnyObject).lock()
    return 0
}

@discardableResult public func objc_sync_exit(_ obj: Any) -> Int32 {
    syncLock(obj as AnyObject).unlock()
    return 0
}

// MARK: - simd

public typealias simd_float4 = SIMD4<Float>
public typealias simd_float3 = SIMD3<Float>

public struct simd_float4x4: Equatable {
    public var columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)
    public init(_ c0: SIMD4<Float>, _ c1: SIMD4<Float>, _ c2: SIMD4<Float>, _ c3: SIMD4<Float>) { columns = (c0, c1, c2, c3) }
    public static func == (a: simd_float4x4, b: simd_float4x4) -> Bool {
        a.columns.0 == b.columns.0 && a.columns.1 == b.columns.1 && a.columns.2 == b.columns.2 && a.columns.3 == b.columns.3
    }
}

public let matrix_identity_float4x4 = simd_float4x4(SIMD4(1, 0, 0, 0), SIMD4(0, 1, 0, 0), SIMD4(0, 0, 1, 0), SIMD4(0, 0, 0, 1))

// MARK: - CoreMedia / CoreVideo / VideoToolbox

public typealias OSStatus = Int32
public typealias OSType = UInt32
public let noErr: OSStatus = 0
public let kCMVideoCodecType_AV1: OSType = 0x6176_3031 // 'av01'
public let kCMVideoCodecType_HEVC: OSType = 0x6876_6331 // 'hvc1'
public let kVTVideoDecoderBadDataErr: OSStatus = -12909
public let kVTInvalidSessionErr: OSStatus = -12903

/// What the harness decoder knows about a stream: the config the session was created from.
public final class CMFormatDescription: CustomStringConvertible {
    public let width: Int
    public let height: Int
    public let configId: UInt32
    public init(width: Int, height: Int, configId: UInt32) {
        self.width = width
        self.height = height
        self.configId = configId
    }
    public var description: String { "CMFormatDescription(\(width)x\(height) config \(configId))" }
}

/// A decoded picture: which frame it came from.
public final class CVImageBuffer {
    public let frameIndex: UInt32
    public let timestamp: UInt64
    public init(frameIndex: UInt32, timestamp: UInt64) {
        self.frameIndex = frameIndex
        self.timestamp = timestamp
    }
}

/// The harness decoder session (state lives in the harness's VideoHandler stand-in).
public final class VTDecompressionSession {
    public let format: CMFormatDescription
    public var invalidated = false
    public var lastDecodedIndex: UInt32? = nil
    public var decodedCount = 0
    public var errorCount = 0
    public init(format: CMFormatDescription) { self.format = format }
}

public func VTIsHardwareDecodeSupported(_ codec: OSType) -> Bool { false }

// MARK: - AVKit (audio session: inert)

public final class AVAudioSession {
    public static func sharedInstance() -> AVAudioSession { shared }
    nonisolated(unsafe) private static let shared = AVAudioSession()
    public enum Category { case playAndRecord }
    public enum Mode { case voiceChat }
    public struct CategoryOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let mixWithOthers = CategoryOptions(rawValue: 1)
        public static let allowBluetoothA2DP = CategoryOptions(rawValue: 2)
        public static let allowAirPlay = CategoryOptions(rawValue: 4)
    }
    public enum SpatialExperience { case bypassed }
    public func setActive(_ active: Bool) throws {}
    public func setCategory(_ c: Category, options: CategoryOptions = []) throws {}
    public func setMode(_ m: Mode) throws {}
    public func setPreferredOutputNumberOfChannels(_ n: Int) throws {}
    public func setIntendedSpatialExperience(_ e: SpatialExperience) throws {}
}

// MARK: - Network (mDNS listener: inert)

public struct NWTXTRecord {
    public init(_ d: [String: String]) {}
}

public final class NWConnection {
    public func cancel() {}
}

public enum NWError: Error { case posix(Int32) }

public final class NWListener {
    public enum Parameters { case tcp }
    public enum State { case setup, ready, waiting(NWError), failed(NWError), cancelled }
    public struct Service {
        public init(name: String, type: String, txtRecord: NWTXTRecord) {}
    }
    public enum ServiceRegistrationChange { case add }
    public var service: Service? = nil
    public var stateUpdateHandler: ((State) -> Void)? = nil
    public var serviceRegistrationUpdateHandler: ((ServiceRegistrationChange) -> Void)? = nil
    public var newConnectionHandler: ((NWConnection) -> Void)? = nil
    public init(using: Parameters) throws {}
    public func start(queue: DispatchQueue) {}
    public func cancel() {}
}

// MARK: - UIKit (app state is scriptable: a scenario can put the app "in the background")

public final class UIApplication {
    public enum State { case active, inactive, background }
    nonisolated(unsafe) public static let shared = UIApplication()
    private let lock = NSLock()
    private var _state: State = .active
    public var applicationState: State {
        get { lock.lock(); defer { lock.unlock() }; return _state }
        set { lock.lock(); _state = newValue; lock.unlock() }
    }
}

public final class UIDevice {
    public enum BatteryState { case unknown, unplugged, charging, full }
    nonisolated(unsafe) public static let current = UIDevice()
    public var isBatteryMonitoringEnabled = true
    public var batteryLevel: Float = 0.8
    public var batteryState: BatteryState = .unplugged
}

// MARK: - Combine (ObservableObject / @Published without the publisher machinery)

public protocol ObservableObject: AnyObject {}

@propertyWrapper public struct Published<Value> {
    public var wrappedValue: Value
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
}

// MARK: - Foundation gaps on Linux

extension Thread {
    @discardableResult public class func setThreadPriority(_ p: Double) -> Bool { true }
}

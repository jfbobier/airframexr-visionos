//
//  GlobalSettings.swift
//
// Client-side settings and defaults
//

import Foundation
import SwiftUI
import simd

struct GlobalSettings: Codable {
    var keepSteamVRCenter: Bool = false
    var showHandsOverlaid: Bool = false
    var disablePersistentSystemOverlays: Bool = true
    var streamFPS: String = "Default"
    var chromaKeyEnabled: Bool = false
    var chromaKeyFromStreamer: Bool = true
    var chromaKeyDistRangeMin: Float = 0.35
    var chromaKeyDistRangeMax: Float = 0.7
    var chromaKeyColorR: Float = 16.0 / 255.0
    var chromaKeyColorG: Float = 124.0 / 255.0
    var chromaKeyColorB: Float = 16.0 / 255.0
    var dismissWindowOnEnter: Bool = true
    /// Floor height offset in centimetres, added to whatever height the headset reports; positive raises the
    /// player in the game. 0 = the headset's reading as is.
    var heightOffsetCm: Int = 0
    /// Enter the streamer as soon as the connection is up, without pressing Enter.
    var autoConnect: Bool = false
    var targetHandsAtRoundtripLatency = false
    var showFaceTrackingDebug = false
    var lastUsedAppVersion = "never launched"
    var chaperoneDistanceCm: Int = 0
    var showPerformanceHud: Bool = false
    var claimControllerHomeButton: Bool = true
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.keepSteamVRCenter = try container.decodeIfPresent(Bool.self, forKey: .keepSteamVRCenter) ?? self.keepSteamVRCenter
        self.showHandsOverlaid = try container.decodeIfPresent(Bool.self, forKey: .showHandsOverlaid) ?? self.showHandsOverlaid
        self.disablePersistentSystemOverlays = try container.decodeIfPresent(Bool.self, forKey: .disablePersistentSystemOverlays) ?? self.disablePersistentSystemOverlays
        self.streamFPS = try container.decodeIfPresent(String.self, forKey: .streamFPS) ?? self.streamFPS
        self.chromaKeyEnabled = try container.decodeIfPresent(Bool.self, forKey: .chromaKeyEnabled) ?? self.chromaKeyEnabled
        self.chromaKeyFromStreamer = try container.decodeIfPresent(Bool.self, forKey: .chromaKeyFromStreamer) ?? self.chromaKeyFromStreamer
        self.chromaKeyDistRangeMin = try container.decodeIfPresent(Float.self, forKey: .chromaKeyDistRangeMin) ?? self.chromaKeyDistRangeMin
        self.chromaKeyDistRangeMax = try container.decodeIfPresent(Float.self, forKey: .chromaKeyDistRangeMax) ?? self.chromaKeyDistRangeMax
        self.chromaKeyColorR = try container.decodeIfPresent(Float.self, forKey: .chromaKeyColorR) ?? self.chromaKeyColorR
        self.chromaKeyColorG = try container.decodeIfPresent(Float.self, forKey: .chromaKeyColorG) ?? self.chromaKeyColorG
        self.chromaKeyColorB = try container.decodeIfPresent(Float.self, forKey: .chromaKeyColorB) ?? self.chromaKeyColorB
        self.dismissWindowOnEnter = try container.decodeIfPresent(Bool.self, forKey: .dismissWindowOnEnter) ?? self.dismissWindowOnEnter
        self.heightOffsetCm = try container.decodeIfPresent(Int.self, forKey: .heightOffsetCm) ?? self.heightOffsetCm
        self.autoConnect = try container.decodeIfPresent(Bool.self, forKey: .autoConnect) ?? self.autoConnect
        self.targetHandsAtRoundtripLatency = try container.decodeIfPresent(Bool.self, forKey: .targetHandsAtRoundtripLatency) ?? self.targetHandsAtRoundtripLatency
        self.showFaceTrackingDebug = try container.decodeIfPresent(Bool.self, forKey: .showFaceTrackingDebug) ?? self.showFaceTrackingDebug
        self.lastUsedAppVersion = try container.decodeIfPresent(String.self, forKey: .lastUsedAppVersion) ?? self.lastUsedAppVersion
        self.chaperoneDistanceCm = try container.decodeIfPresent(Int.self, forKey: .chaperoneDistanceCm) ?? self.chaperoneDistanceCm
        self.showPerformanceHud = try container.decodeIfPresent(Bool.self, forKey: .showPerformanceHud) ?? self.showPerformanceHud
        self.claimControllerHomeButton = try container.decodeIfPresent(Bool.self, forKey: .claimControllerHomeButton) ?? self.claimControllerHomeButton
    }
}

extension GlobalSettingsStore {
    static let sampleData: GlobalSettingsStore =
    GlobalSettingsStore()
}

class GlobalSettingsStore: ObservableObject {
    @Published var settings: GlobalSettings = GlobalSettings()
    
    init() {
        try? load()
    }

    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true)
        .appendingPathComponent("globalsettings.data")
    }
    
    func load() throws {
        let fileURL = try Self.fileURL()
        guard let data = try? Data(contentsOf: fileURL) else {
            return self.settings = GlobalSettings()
        }
        let globalSettings = try JSONDecoder().decode(GlobalSettings.self, from: data)
        self.settings = globalSettings
    }
    
    func save(settings: GlobalSettings) throws {
        let data = try JSONEncoder().encode(settings)
        let outfile = try Self.fileURL()
        try data.write(to: outfile)
    }
}

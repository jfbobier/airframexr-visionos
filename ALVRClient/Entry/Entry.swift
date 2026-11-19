/*
Abstract:
The Entry content for a volume: connection status, a few switches and the Enter button, in one column so nothing sits outside the window.
*/

import SwiftUI
import UIKit

struct Entry: View {
    @ObservedObject var eventHandler = EventHandler.shared
    @EnvironmentObject var gStore: GlobalSettingsStore
    @ObservedObject var floorReadout = FloorReadout.shared
    /// True while the reading is coming from the headset right now; dimmed when it is the last session's.
    @State private var floorReadingIsLive = false
    @Environment(\.scenePhase) private var scenePhase
    let saveAction: ()->Void

    private var heightOffsetCm: Binding<Double> {
        Binding(
            get: { Double(gStore.settings.heightOffsetCm) },
            set: { gStore.settings.heightOffsetCm = Int($0.rounded()) }
        )
    }

    /// "HMD 1.62 m + offset +5 cm = 1.67 m"
    private var heightLine: String {
        let offset = gStore.settings.heightOffsetCm
        guard let head = floorReadout.headY else {
            return String(format: "HMD – + offset %+d cm = –", offset)
        }
        return String(format: "HMD %.2f m + offset %+d cm = %.2f m", head, offset, head + Float(offset) / 100.0)
    }

    var body: some View {
        VStack(spacing: 20) {
        VStack {
            VStack {
                Image(.alvrCombinedLogoHqLight)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .accessibilityLabel("AirFrameXR logo")
                .frame(maxWidth: .infinity, maxHeight: 150)
                .padding(.top)

                VStack {
                    Text(eventHandler.connectionFlavorText)
                        .font(.system(size: 15))
                }
                .frame( maxWidth: .infinity, minHeight: 50, maxHeight: 50, alignment: .top)
            }
            .frame(minHeight: 200)

            VStack {
                Text(heightLine)
                    .monospacedDigit()
                    .foregroundStyle(floorReadingIsLive ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                        guard !EventHandler.shared.renderStarted else { return }
                        if let y = WorldTracker.shared.currentHeadHeight() {
                            floorReadingIsLive = true
                            floorReadout.record(headY: y)
                        } else {
                            floorReadingIsLive = false
                        }
                    }
                Slider(value: heightOffsetCm, in: -50...50, step: 1) {
                    Text("Floor height offset")
                }
                .onChange(of: gStore.settings.heightOffsetCm) {
                    saveAction()
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // 1.4: the field of view and the picture are set in the streamer on the PC (the H / V FoV sliders are gone)
            Text("Field of view and picture: set in the streamer on the PC")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top)

            VStack {
                Toggle(isOn: Binding(
                    get: { gStore.settings.chaperoneDistanceCm > 0 },
                    set: { gStore.settings.chaperoneDistanceCm = $0 ? 30 : 0; saveAction() }
                )) {
                    Text("Proximity chaperone")
                }
                .toggleStyle(.switch)
                Toggle(isOn: $gStore.settings.autoConnect) {
                    Text("Auto-connect")
                }
                .toggleStyle(.switch)
                .onChange(of: gStore.settings.autoConnect) {
                    saveAction()
                }
                Toggle(isOn: $gStore.settings.streamAudioWhenHeadsetOff) {
                    Text("Stream audio when headset removed")
                }
                .toggleStyle(.switch)
                .onChange(of: gStore.settings.streamAudioWhenHeadsetOff) {
                    EventHandler.shared.holdStreamWhenHeadsetOff = gStore.settings.streamAudioWhenHeadsetOff
                    saveAction()
                }
            }
            .padding(.horizontal)
            .padding(.top)

            VStack {
                if eventHandler.hostname != "" && eventHandler.IP != "" {
                    let columns = [
                        GridItem(.fixed(150), alignment: .trailing),
                        GridItem(.fixed(150), alignment: .leading)
                    ]

                    LazyVGrid(columns: columns) {
                        Text("hostname:")
                        Text(eventHandler.hostname)
                        Text("IP:")
                        Text(eventHandler.IP)
                    }
                    .frame(width: 300, alignment: .center)
                    .padding(.vertical)
                }
            }
        }
        .frame(minWidth: 650, maxWidth: 650)
        .padding(.bottom)
        .glassBackgroundEffect()
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .background, .inactive:
                saveAction()
            case .active:
                break
            @unknown default:
                break
            }
        }

        EntryControls(saveAction: saveAction)
            .padding(.bottom, 24)
        }
    }
}


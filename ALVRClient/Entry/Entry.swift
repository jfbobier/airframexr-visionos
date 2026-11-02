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

    private var floorReading: String {
        guard let head = floorReadout.headY else {
            return "–"
        }
        return String(format: "%.2f m", head)
    }

    private var gameHeight: String {
        guard let head = floorReadout.headY else {
            return "–"
        }
        return String(format: "%.2f m", head + Float(gStore.settings.heightOffsetCm) / 100.0)
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

                if eventHandler.alvrVersion != "" {
                    Text(eventHandler.alvrVersion)
                        .font(.system(size: 20, weight: .bold))
                }
                else {
                    Text("Loading settings...")
                        .font(.system(size: 20, weight: .bold))
                }

                VStack {
                    Text(eventHandler.connectionFlavorText)
                        .font(.system(size: 15))
                }
                .frame( maxWidth: .infinity, minHeight: 50, maxHeight: 50, alignment: .top)
            }
            .frame(minHeight: 200)

            VStack {
                HStack {
                    Text("Headset height above floor")
                    Spacer()
                    Text(floorReading)
                        .foregroundStyle(floorReadingIsLive ? .primary : .secondary)
                }
                    .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                        guard !EventHandler.shared.renderStarted else { return }
                        if let y = WorldTracker.shared.currentHeadHeight() {
                            floorReadingIsLive = true
                            floorReadout.record(headY: y)
                        } else {
                            floorReadingIsLive = false
                        }
                    }
                HStack {
                    Text("+ Manual height offset")
                    Spacer()
                    Text(gameHeight)
                        .foregroundStyle(floorReadingIsLive ? .primary : .secondary)
                }
                .padding(.top)
                Slider(value: heightOffsetCm, in: -50...50, step: 1) {
                    Text("Floor height offset")
                }
                .onChange(of: gStore.settings.heightOffsetCm) {
                    saveAction()
                }
            }
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
                Toggle(isOn: $gStore.settings.showPerformanceHud) {
                    Text("Performance HUD (left forearm)")
                }
                .toggleStyle(.switch)
                .onChange(of: gStore.settings.showPerformanceHud) {
                    saveAction()
                }
                Toggle(isOn: $gStore.settings.autoConnect) {
                    Text("Auto-connect")
                }
                .toggleStyle(.switch)
                .onChange(of: gStore.settings.autoConnect) {
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
                        Text("Streamer Version:")
                        if eventHandler.hostAlvrVersion != "" {
                            Text(eventHandler.hostAlvrVersion)
                        }
                        else {
                            Text("Disconnected")
                        }
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
        }
    }
}

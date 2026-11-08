/*
Abstract:
Controls that allow entry into the ALVR environment.
*/

import SwiftUI

/// Controls that allow entry into the ALVR environment.
struct EntryControls: View {
    @Environment(ViewModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    @ObservedObject var eventHandler = EventHandler.shared
    @EnvironmentObject var gStore: GlobalSettingsStore
    
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    
    let saveAction: ()->Void

    var body: some View {
        @Bindable var model = model
        
        HStack(spacing: 17) {
            if eventHandler.connectionState == .connected {
                Toggle(isOn: $model.isShowingClient) {
                    Label("Enter", systemImage: "visionpro")
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 22)
                }
            } else {
                Label("Connecting...", systemImage: "visionpro")
                    .labelStyle(.titleOnly)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 22)
            }
            
        }
        .toggleStyle(.button)
        .buttonStyle(.borderless)
        .glassBackgroundEffect(in: .rect(cornerRadius: 50))

        // Auto-connect: enter when the streamer connects (the edge, not the level, so leaving the stream
        // on purpose while still connected does not throw you back in), or when the switch is turned on
        // while already connected.
        .onChange(of: eventHandler.connectionState) { _, state in
            if state == .connected && gStore.settings.autoConnect && !model.isShowingClient {
                model.isShowingClient = true
            }
        }
        .onChange(of: gStore.settings.autoConnect) { _, on in
            if on && eventHandler.connectionState == .connected && !model.isShowingClient {
                model.isShowingClient = true
            }
        }

        //Enable Client
        .onChange(of: model.isShowingClient) { _, isShowing in
            Task {
                if isShowing {

                    saveAction()
                    print("Opening Immersive Space")
                    await openImmersiveSpace(id: "MetalClient")
                    VideoHandler.applyRefreshRate(videoFormat: EventHandler.shared.videoFormat)
                    if gStore.settings.dismissWindowOnEnter {
                        dismissWindow(id: "Entry")
                    }
                }
            }
        }

    }
}

# AirFrameXR client for Apple Vision Pro: version history

Moved out of the README on 2026-11-20. Newest first. Each entry says what was tried on a headset and what was not.

## 1.4.1 (foundation test build)

Built in CI for TestFlight; **not tried on a headset**, nothing compiled locally (no Xcode on the dev machine).

- **No stand-in views.** Before its immersive space rendered (and while the headset was off) the app sent fake view parameters with its fake
  tracking: Apple's raw frustum with both eyes at one point. A game started in that window took them as the headset's view (Star Wars Galactic
  Racer, 2026-11-20: 1950 x 1804 per eye instead of 2624 x 2368, most likely no stereo). The app now sends only the fake tracking; it declares
  its view once its renderer has the real one. Pairs with the AirFrameXR streamer (which needs no views to stream, and gives a game that starts
  early the box it sent the app); a stock ALVR streamer is not a target of this build.

## 1.4.0

Built in CI and sent to TestFlight; **not tried on a headset**, and nothing of it was compiled locally (no Xcode on the dev machine).

- **The streamer owns the field of view.** The H / V FoV sliders and the Default FoV switch are gone. The streamer sends one box per
  connection (over `ServerControlPacket::Reserved`, a client_core patch) and the app declares it as it is, clamped to the compositor's
  circumscribed frustum. With no message (an older streamer) the app declares the compositor's whole frustum, as before. Design:
  `docs/FOV_CONTRACT_PLAN.md` in the AirFrameXR repository.
- **Sharpening on the magnified luma (AMD FidelityFX CAS, MIT).** A single-pass "sharpen and scale" form of contrast adaptive sharpening on the
  luma plane only, for the 1.2 to 1.7 x magnification at the centre of the view. Off unless the streamer switches it on in the same
  message; the Catmull-Rom reconstruction of 1.3.8 stays the default.
- **Auto-recenter on stream start** (switch, off by default, `autoRecenterOnStart`): about 90 poses after a stream starts, the head's floor
  position and heading become the stream's origin.
- **Recenter = Create + Options** on the PSVR2 Sense controllers: pressing both at once recenters the same way (`recenterOnHead`).
  While the other button is down a press is not sent to the game, so Create does not pause UEVR games. Only the yaw and the floor position
  change; a long Digital Crown press (visionOS's own recenter) is separate. The old triple-press detection only runs with
  `keepSteamVRCenter`, which nothing in the app sets.
- **Flat2VR mode for PSVR2 buttons** (switch, on by default, `flat2vrButtons`): Flat2VR games assume an Xbox controller (Create = View,
  Options = Menu). **The setting is stored but not wired**: the Quest 2 emulation the stream uses has no View button, so the mapping
  needs a streamer-side gamepad profile or a decision on which Touch inputs to reuse.
- **Audio keep-alive ("Stream audio when headset removed")** (switch, on by default, `streamAudioWhenHeadsetOff`, from 1.3.11). Take the
  headset off with a stream up and the connection stays: the game keeps running and its audio keeps playing, no picture is decoded
  while the headset is off, and the picture comes back when it is put on again (the decoder is rebuilt from the saved parameter sets with a
  keyframe, and the immersive space is opened again if it has not rendered 2 s after). The app is kept alive in the background for up to
  30 min (`backgroundHoldMax`, a bound, not a setting) with `UIBackgroundModes: audio`, the audio session left on and fake tracking sent so
  the streamer does not see the headset vanish; after that, or with the switch off, the app leaves as it did before 1.3.11.
  Not tried on a headset for the full time: what is still unknown is how long visionOS lets the app run in the background and whether the
  headset plays the audio while not worn. The `[stream] ...background...` lines in the streamer log show what happened.
- **Entry window**: Auto-connect card, version line, connection dot (above).
- Video after a headset-off hold: a frame VideoToolbox refuses counts as a failed decode, the decoder is rebuilt from the saved parameter
  sets after a hold, and the immersive space is opened again if it has not rendered 2 s after the headset is back.

## 1.3.11

Headset off keeps the stream (the user takes the headset off to open the door, the game audio goes on, the picture is back when it is
put on again). **Not tried on a headset**: checked in the protocol harness on Linux and compiled there only; the App Store build is
under review, so nothing of this was pushed or built in CI.

- **A switch "Stream audio when headset removed"** on the Entry window, on by default (`streamAudioWhenHeadsetOff`); off = the app leaves in the
  background as before. The version line under the logo and the "Streamer Version" row are gone from the Entry window (not useful to users).
- **`UIBackgroundModes: audio`** in `Info.plist` (the app does play the game's audio) so visionOS does not suspend it at once.
- **With a stream up, the background no longer ends the app.** `EventHandler.exitIfBackgrounded` holds the connection for up to
  30 min (`backgroundHoldMax`, a bound, not a setting): no picture is decoded (`handleNals` drops it), the fake-tracking keep-alive
  runs like before the space opened, and the audio session is left on. Without a stream, or after the bound, the app exits as before.
- **A layer that ends with the headset off** (`MetalClientSystem.renderLoop`) no longer calls `alvr_pause()`; the app re-enters the
  immersive space by itself when it is back (`onResumeStream`), asks for a keyframe, and the stream never stopped.
- What is unknown until measured on a headset: how long visionOS lets the app run in the background, whether the headset plays audio
  while not worn, and whether the layer is paused or invalidated when it comes off (the logs `[stream] ...background...` show it).

## 1.3.10

Hardening against a lost or stalled link (AirFrameXR `docs/VISIONOS_CLIENT_HARDENING.md`). Checked in the protocol harness on Linux and,
for the client_core patch, on the streamer's lab with the mock headset; not yet on a headset. No change to pacing or picture.

- **A lost link no longer leaves a frozen scene.** The client stays in the immersive space and the stream resumes by itself when the
  streamer is back; after 60 s without a stream (`EventHandler.leaveStreamAfter`) it leaves the space for the Entry window, and
  auto-connect re-enters when the streamer is found again.
- **Shorter lock holds between the render thread, the decoder callback and client_core.** `alvr_report_frame_decoded` is called outside
  `frameQueueLock`, and client_core sends its statistics packet after releasing its statistics mutex
  (`patches/client_core-statistics-send-outside-lock.patch`, applied to the ALVR submodule by `scripts/apply_core_patches.sh` at build time).
- **Metal giving no command buffer skips the frame** instead of ending the app.

## 1.3.9

Pacing, measured on an M2 Vision Pro on 2026-11-10 (pacing test rig, then a TestFlight A/B on the headset). The picture work of 1.3.8 is unchanged.

- **The pick waits 8 ms for a late frame** (stock 5 ms): +1.1 points of new frames per tick, repeated ticks down by 29%, about 0.5 ms
  more queue age, a deadline-miss count that stays about 1 per 1000. `Renderer.swift`, the `pollFrameForDisplay` call.
- **100 Hz hack.** When the streamer asks for 90 Hz the client asks visionOS for 100 Hz (`VideoHandler.applyRefreshRate`), on every
  Vision Pro including the M5 so there is one rule. It is a request visionOS may refuse. The reason: the 100 Hz mode missed about 3 frames
  per 1000, a real 90 Hz stay about 23, and the headset ran 100 Hz in the sessions measured even when 90 was asked. The stream rate stays
  the negotiated one. If a later visionOS makes 90 Hz fine, delete the two lines of `displayRequest`.
- The telemetry added for 1.3.8 and the pose-fetch experiments (the `[tele]` lines in the streamer log) is removed; the catch-up pick stays as a lab switch (`EventHandler.catchUpPick`, off)
  because the protocol harness drives it.

## 1.3.8

Picture quality: two changes in the shader and the texture path, no setting for either.

- **Bicubic chroma.** The two colour planes of the 4:2:0 picture are half the luma resolution, so they are always enlarged.
  They are now sampled with a Catmull-Rom filter (`sampleCatmullRom5` in `Shaders.metal`: five bilinear taps with the weights
  renormalised, so the cost is five texture reads instead of the full sixteen). It passes exactly through the stored values, so
  flat colour and 1:1 areas do not change; colour fringes on edges (red on dark, text on a coloured background) are tighter.
- **Bicubic luma where the picture is stretched.** The same filter is used for brightness only where one stored texel covers
  more than about one screen pixel (decided per pixel from the sampling footprint): the foveated periphery, or a stream
  encoded below the screen's resolution. Elsewhere the plain bilinear sample is kept, so the centre costs nothing extra.
- **Own colour conversion.** To choose the filter, the video is read as two plain planes (`r8`/`rg8`, `r16`/`rg16` for 10-bit) and
  converted with the YCbCr matrix of the stream's encoding, instead of Apple's private converting formats, which filter the
  colour inside the sample where the shader cannot reach. The colour was checked on a Vision Pro by the owner (the first
  build with the filters: colours and sharpness good). `forceFastSecretTextureFormats` in `VideoHandler.swift` goes back to the old formats
  with one constant, filters and all.
- **Cost, measured on the device** (lines `[tele] draw over ...` in the streamer's `alvr.log`): the GPU draw takes about
  4.0 ms per frame at 100 Hz (2.2 ms with the hardware formats and no filters, on a different, larger stream, so the two
  numbers are not a clean comparison; the filter's share is at most the difference and is largest on a small stream). In
  196,388 frames, 4 command buffers finished after their presentation time; the GPU is not what misses a frame.
- Not in the client on purpose: sharpening (contrast adaptive or otherwise) alters the image and is done on the streamer.

Not picture: the frame pick shows the newer of two queued frames after a stall (less lag after a refresh-rate switch), the
client's refresh rate follows the rate the stream negotiates, and the `[tele]` lines in `alvr.log` (display interval, draw
cost, pick, CPU split) that these were measured with. See `docs/VISIONOS_TELEMETRY_LEARNINGS.md` in the AirFrameXR repository.

## 1.3.6

- Aligned with the AirFrameXR 1.3.6 PC package; this is the first build that carries everything below. `airframexr-client` is the
  release branch (the 1.4 line is retired: no streamer-driven view, the app keeps the FoV Scale slider).
- The encoding gamma the app asks the streamer for is now **1.2** (was 1.5), the value reported as the best for the Vision Pro; the app decodes with whatever the streamer negotiates, so a streamer that overrides it still wins. (Was committed after TestFlight build 1.3.5.)
- The **FoV Scale** slider (below, from 1.3.5) is in this build, as **two sliders**, Horizontal and Vertical (0.6 to 1.4, centred on 1.0) behind a **Default FoV** switch (on by default; turning it on resets both to 1.0). A setting saved by an earlier build
  is carried to both, with the switch off. Above 1.0 the app declares more angle than the compositor's frustum (1.3.5 capped at 1.0 after the old 1.1 did that): untested on a headset.
- The Performance HUD (left forearm) and the frame timing it needed are removed.
- The height rows are one line: `HMD 1.62 m + offset +5 cm = 1.67 m`. The Enter button has more room.

## 1.3.5

- The **FoV Scale** slider is back (0.70 to 1.00, 0.05 steps, 1.00 = the compositor's whole frustum), on top of the declared
  frustum: a user who likes a tighter, sharper stream can pick it without any calibration; the PC-side restriction is a
  separate control (it only changes what the game renders). The slider never goes above Apple's frustum (the 1.1 of the
  old build asked for more angle than the headset has).
- The temporary `[ratemap]` probe of 1.3.2 is removed: no diagnostic lines are written into the streamer's log any more.
- Version aligned with the AirFrameXR 1.3.5 PC package.

## 1.3.2 (not built yet)

- The fixed field-of-view ceiling is gone: the app declares the compositor's own frustum, as the stock app does at
  FoV Scale 1. A tester saw black bars with the streamer's restriction off on 1.3.1 and none on the stock app: the
  ceiling, measured on two wearers, was smaller than his view. Cost: the stream spreads over about twice the area
  (left eye 1.79 / 1.02 / 1.22 / 1.02 against about 1.05 / 0.80 / 0.76 / 0.87), so about 1.4 times fewer pixels per
  degree per axis, the stock app's sharpness. A calibrated wearer still gets the game restricted to the rectangle
  (the streamer converts the absolute tangents against the new box); the sharpness comes back only when the
  streamer can tell the app which box to declare (Next).
- (Removed in 1.3.5) TEMPORARY `[ratemap]` lines in the streamer's log, the compositor's rasterization rate map sampled
  across each eye.

## 1.3.1 (2026-11-02)

Stream transitions: the app going unstable, or closing itself, when the stream starts, when a game stalls or loads, or when the frame
rate drops. Found with a new protocol harness (`tools/protocol-harness/`, below) that runs the app's own `EventHandler.swift` on Linux
against a scripted streamer, plus ThreadSanitizer. TestFlight build 21 (the transition fixes, before the hand input below was
removed): testers report no transition errors any more (2026-11-02).

- All hand input is removed: the system pinch gesture (and the double pinch that sent A / X), hands as controllers, the hand skeleton, the
  "Hands as controllers" switch and the controllers-clack toggle. Users reported random commands from the pinch. ARKit hand tracking
  still runs, only to fuse the Steam Controller pose from the hands holding it. Without a controller, a Steam Controller or a gamepad the
  app now sends no input at all (so the desktop mirror cannot be clicked either). Settings saved by earlier builds are ignored.

- A game that sends nothing for 30 s (a long loading screen) no longer makes the app drop the connection. It reconnects only when
  frames arrive and none decode for 30 s.
- A new decoder when the streamer's stream configuration changes on the same connection (AirFrameXR does this when a game exits after
  a deferred stream change). The old decoder was kept and the picture froze until the app was restarted. A decoder that shows no
  picture for a second of frames is also rebuilt.
- The app no longer closes on a short "background" report from visionOS: it leaves once the background state has held for one second.
- The decoder, the frame queue and the last shown frame are shared by the network, render and event threads. They are now read and
  written under one lock, so a stream stop or restart cannot swap them under a thread that is using them. These were ThreadSanitizer
  findings and crash candidates at every transition.
- Smaller fixes:
  - A tracking worker that could wait forever after startup.
  - Render pipeline rebuilds run one at a time (several used to run at once at every stream start).
  - A frame finished after its presentation time reports no queue time, instead of a wrapped value that held head prediction at its
    cap.
- Transitions write `[stream]` lines into the streamer's log: decoder rebuilds, the reconnect rule, background exits. If the app
  still closes, look there first.

Not covered by the harness: Metal, the real VideoToolbox and the visionOS watchdog. Its streamer answers an IDR request instantly,
so its recovery times are best cases.

**Protocol harness:** `tools/protocol-harness/build.sh [--tsan]` then `run.sh [--tsan]` (Swift for Linux, no Mac). In the AirFrameXR
repository, `python3 harness/stability/run_stability.py client [--tsan]` runs the same thing. Before / after on the same 15
scenarios:

| Scenario | 1.2.2 | 1.3.1 |
|---|---|---|
| 35 s stall | the app drops the connection | passes |
| encoder rebuilt mid-connection | picture frozen | passes |
| 0.3 s background report | the app closes | passes |
| idle to game, fps drops, 1 / 6 s stalls, choking game, irregular cadence, restarts | pass | pass |
| ThreadSanitizer | races on the decoder and the last shown frame | only simple counters and timers left |

## 1.2.2 (2026-10-31)

- Finger pinches are ignored while a regular gamepad (DualSense, Xbox, Joy-Con) is connected. A pinch caught by accident used to take
  the trigger and pointer from the gamepad for a few seconds (user report). Tracked PS VR2 Sense controllers are not affected (they are
  handled per hand). Built by CI only; not tested on a headset. Any connected gamepad switches pinches off, used or idle.

## 1.2.1 (2026-10-30)

- The ring outside the declared frame follows the picture's own edge when a chroma key is on: opaque black where the edge is picture (a
  game), transparent where it is the key colour (between games, around the desktop mirror), so the idle passthrough is no longer framed
  in black. Drawn as four thin strips around the frame (no overdraw of the picture), one texture sample per pixel, only while a key is on;
  decided on the GPU from the decoded frame, so it changes on the same frame as the picture. Not measured on a headset yet (GPU time
  with and without the ring is the check owed).

## 1.2.0 (2026-10-29)

Released together with AirFrameXR streamer 1.2.0; the two are numbered together from now on. TestFlight builds 17
and 18 (version 1.2.0) carry everything below except the double tap, which is committed and not yet built.

- The declared field of view is a ceiling, the calibration lives on the PC (above). A second wearer who needed
  0.80 at the bottom could not get it before: the old fixed box stopped at 0.77.
- The hand click is the system pinch gesture (above). Found with a `[pinch]` debug line the calibration builds
  wrote every 2 s into the streamer's log: the hand was untracked 70 % of the time with the hand at the side, and
  the skeleton distance read 1.4 to 2.5 cm on real pinches against a 2 cm threshold.
- Black outside the frame whatever the chroma key, and the chroma key itself working again with it (the first
  attempt cleared to opaque black and discarded keyed pixels, which left that black in place; keyed pixels are
  now written transparent).
- Two pinches in a row send A / X: a double click on the desktop mirror. Not built or tried on a device yet.
- TestFlight workflow: the certificate revoke step; default version 1.2.0.

Not done, by choice: the pinch keeps Apple's recognizer timing (a deliberate pinch, no quick flick); nothing
calibration-related is set on the headset.

## Next

- The wearer's rectangle declared by the client itself, on the streamer's order (a host-to-client message on the
  v20 protocol's reserved packet): the stream frame could then cover only the rectangle, which the AirFrameXR
  measurements put at 30 % fewer encoded pixels on a full-frame stream. Until then the ceiling is what the stream
  covers.
- The field-of-view sweep drawn by the client itself, with the pinch read from hand tracking, if the streamed
  sweep (`tools/fov_calibration_bundle` in the AirFrameXR repository) proves too dependent on the hand staying in
  the cameras' view.

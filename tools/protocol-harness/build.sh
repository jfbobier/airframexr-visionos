#!/bin/bash
# Protocol harness for the visionOS client: compiles the REAL ALVRClient/EventHandler.swift on Linux against stand-ins
# for the Apple frameworks (Shims/), a scripted client_core + streamer (Harness/FakeCore.swift) and a render-loop model
# (Harness/DisplaySim.swift). No Mac, no Xcode, no headset.
#
#   tools/protocol-harness/build.sh [--tsan]      -> tools/protocol-harness/build/protocol_harness[_tsan]
#   tools/protocol-harness/run.sh [scenario...]   -> runs scenarios, prints a table
#
# SWIFTC: a Swift 6.x toolchain for Linux (default `swiftc-linux` if present, else `swiftc`).
# CAlvr/alvr_client_core.h is cbindgen output for ALVR/alvr/client_core (same command as build_and_repack.sh:29);
# regenerate it when the submodule moves.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SWIFTC="${SWIFTC:-$(command -v swiftc-linux || command -v swiftc)}"
OUT="$HERE/build"
SAN=()
SUFFIX=""
if [[ "${1:-}" == "--tsan" ]]; then SAN=(-sanitize=thread); SUFFIX="_tsan"; fi
MOD="$OUT/modules$SUFFIX"
mkdir -p "$MOD"

COMMON=(-swift-version 5 -Onone -I "$HERE/CAlvr" -I "$MOD" "${SAN[@]}")

# Apple framework stand-ins: one real module + one re-exporting module per framework name the client imports
"$SWIFTC" "${COMMON[@]}" -parse-as-library -emit-module -emit-module-path "$MOD/AppleShims.swiftmodule" \
    -module-name AppleShims -emit-object -o "$MOD/AppleShims.o" "$HERE/Shims/AppleShims.swift"
OBJS=("$MOD/AppleShims.o")
for fw in Metal VideoToolbox Combine AVKit Network UIKit QuartzCore simd; do
    echo "@_exported import AppleShims" > "$MOD/$fw.swift"
    "$SWIFTC" "${COMMON[@]}" -parse-as-library -emit-module -emit-module-path "$MOD/$fw.swiftmodule" \
        -module-name "$fw" -emit-object -o "$MOD/$fw.o" "$MOD/$fw.swift"
    OBJS+=("$MOD/$fw.o")
done

# The client's protocol layer, unmodified
CLIENT=("$REPO/ALVRClient/EventHandler.swift")

"$SWIFTC" "${COMMON[@]}" -g -module-name Harness \
    "${CLIENT[@]}" "$HERE/Harness/AppStubs.swift" "$HERE/Harness/FakeCore.swift" "$HERE/Harness/DisplaySim.swift" \
    "$HERE/Harness/main.swift" "${OBJS[@]}" -o "$OUT/protocol_harness$SUFFIX"
echo "built $OUT/protocol_harness$SUFFIX"

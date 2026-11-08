#!/bin/bash
# Bit-equality check of ALVRClient/FovScale.swift (see FovCheck/main.swift). Needs the harness shims: runs build.sh if they are missing.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SWIFTC="${SWIFTC:-$(command -v swiftc-linux || command -v swiftc)}"
MOD="$HERE/build/modules"
[[ -f "$MOD/simd.swift" ]] || "$HERE/build.sh"
"$SWIFTC" -swift-version 5 -Onone -I "$HERE/CAlvr" -I "$MOD" -o "$HERE/build/fov_check" \
    "$HERE/../../ALVRClient/FovScale.swift" "$HERE/FovCheck/main.swift" "$MOD/AppleShims.o" "$MOD/simd.o" 2>&1 | tail -20
"$HERE/build/fov_check"

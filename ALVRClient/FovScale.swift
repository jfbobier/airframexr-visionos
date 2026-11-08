//
//  FovScale.swift
//
// The two FoV sliders (horizontal, vertical) and how they scale the declared field of view.
// Only `simd` is imported so the protocol harness can check it on Linux (tools/protocol-harness/fov_check.sh).
//

import simd

/// Range of the two FoV sliders.
let fovScaleRange: ClosedRange<Float> = 0.6...1.4

/// The angles declared to the streamer from the compositor's frustum tangents (left, right, up/down, up/down), scaled per axis:
/// horizontal on the left and right edges, vertical on the other two. With scaleH == scaleV the scale vector is (s, s, s, s) and
/// every lane is the same multiply as the single uniform factor of 1.3.5 and earlier: the result is bit for bit the same.
func declaredFovAngles(tangents: simd_float4, scaleH: Float, scaleV: Float) -> simd_float4 {
    let h = max(fovScaleRange.lowerBound, min(fovScaleRange.upperBound, scaleH))
    let v = max(fovScaleRange.lowerBound, min(fovScaleRange.upperBound, scaleV))
    return atan(tangents * simd_float4(h, h, v, v))
}

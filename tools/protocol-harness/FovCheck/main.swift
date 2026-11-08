// Checks ALVRClient/FovScale.swift: with horizontal == vertical the declared angles are bit for bit what 1.3.5 and earlier
// computed with the single FoV Scale (`atan(tangents * s)`), and with H != V each axis follows its own factor.
import Foundation
import simd

func oldDeclared(_ t: simd_float4, _ s: Float) -> simd_float4 { atan(t * max(0.5, min(1.0, s))) }  // 1.3.5, Renderer.swift

var rng = SystemRandomNumberGenerator()
var tangentSets: [simd_float4] = [
    simd_float4(1.73205, 1.0, 1.0, 1.19175), simd_float4(1.0, 1.73205, 1.0, 1.19175),   // the commented-out sample in Drawable.swift
    simd_float4(0.94, 0.93, 0.90, 0.76), simd_float4(1, 1, 1, 1), simd_float4(0.001, 5, 0.3, 2),
]
for _ in 0..<2000 { tangentSets.append(simd_float4(Float.random(in: 0.2...3, using: &rng), Float.random(in: 0.2...3, using: &rng),
                                                   Float.random(in: 0.2...3, using: &rng), Float.random(in: 0.2...3, using: &rng))) }

var failures = 0, checks = 0
func bits(_ v: simd_float4) -> [UInt32] { [v.x.bitPattern, v.y.bitPattern, v.z.bitPattern, v.w.bitPattern] }

// 1. H == V over the whole old slider range (0.70 to 1.00, 0.05 steps) and finer
var s: Float = 0.70
while s <= 1.0001 {
    for t in tangentSets {
        checks += 1
        if bits(declaredFovAngles(tangents: t, scaleH: s, scaleV: s)) != bits(oldDeclared(t, s)) {
            failures += 1; if failures < 5 { print("FAIL equal s=\(s) t=\(t)") }
        }
    }
    s += 0.01
}
// 2. H != V: lanes 0,1 follow H, lanes 2,3 follow V, over the new range
for h in stride(from: Float(0.6), through: 1.4, by: 0.05) {
    for v in stride(from: Float(0.6), through: 1.4, by: 0.05) {
        for t in tangentSets.prefix(200) {
            checks += 1
            let r = declaredFovAngles(tangents: t, scaleH: h, scaleV: v)
            let hh = atan(t * h), vv = atan(t * v)   // plain scalar multiply; no clamp needed inside 0.6...1.4
            if [r.x.bitPattern, r.y.bitPattern, r.z.bitPattern, r.w.bitPattern] != [hh.x.bitPattern, hh.y.bitPattern, vv.z.bitPattern, vv.w.bitPattern] {
                failures += 1; if failures < 5 { print("FAIL axes h=\(h) v=\(v) t=\(t)") }
            }
        }
    }
}
// 3. clamping at the slider ends
checks += 2
if bits(declaredFovAngles(tangents: simd_float4(1,1,1,1), scaleH: 0.1, scaleV: 9)) != bits(atan(simd_float4(0.6, 0.6, 1.4, 1.4))) { failures += 1; print("FAIL clamp") }
if fovScaleRange != 0.6...1.4 { failures += 1; print("FAIL range") }
print("fov_check: \(checks) checks, \(failures) failures")
exit(failures == 0 ? 0 : 1)

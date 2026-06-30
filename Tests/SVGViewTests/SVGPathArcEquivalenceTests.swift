import XCTest
@testable import SVGView

#if canImport(CoreGraphics)
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Verifies that on Apple, the polyfill polyline emission (used on WASI/
/// Linux/Android) produces the same elliptical arc geometry as the
/// transform-based emission used natively on iOS/macOS. Both must trace
/// the same SVG arc — same start point, same end point, same bounding
/// box within a small tolerance dictated by the polyline's 1°/segment
/// chord error.
final class SVGPathArcEquivalenceTests: XCTestCase {

    private struct ArcCase {
        let label: String
        let cx: CGFloat
        let cy: CGFloat
        let w: CGFloat
        let h: CGFloat
        let rotation: CGFloat
        let startAngle: CGFloat
        let arcAngle: CGFloat
    }

    /// Battery of arc parameters covering the regressions PR #16 fixed:
    /// small arcs deep in a viewBox (the "exploded streaks" case),
    /// rotated ellipses, both CW and CCW sweeps, near-full sweeps.
    private static let cases: [ArcCase] = [
        ArcCase(label: "small ellipse near origin, CW half", cx: 50, cy: 50, w: 40, h: 20, rotation: 0, startAngle: 0, arcAngle: .pi),
        ArcCase(label: "rotated ellipse, CW half", cx: 100, cy: 100, w: 60, h: 30, rotation: .pi / 6, startAngle: 0, arcAngle: .pi),
        ArcCase(label: "small arc deep in viewBox (regression case)", cx: 800, cy: 600, w: 10, h: 6, rotation: 0, startAngle: 0, arcAngle: 2 * .pi),
        ArcCase(label: "CCW half sweep", cx: 200, cy: 200, w: 100, h: 50, rotation: 0, startAngle: 0, arcAngle: -.pi),
        ArcCase(label: "rotated small arc, π/3 sweep", cx: 500, cy: 400, w: 16, h: 8, rotation: .pi / 3, startAngle: .pi / 4, arcAngle: .pi / 3),
        ArcCase(label: "rotated CCW arc, π/2 sweep", cx: 300, cy: 300, w: 80, h: 40, rotation: .pi / 4, startAngle: .pi / 2, arcAngle: -.pi / 2),
        ArcCase(label: "near-full sweep", cx: 100, cy: 100, w: 50, h: 30, rotation: 0, startAngle: 0, arcAngle: 1.9 * .pi),
    ]

    func testApplePathAndPolyfillPolylineStartPointsMatch() {
        for c in Self.cases {
            let appleStart = firstPoint(of: applePath(for: c))
            let polylineStart = firstPoint(of: polylinePath(for: c))
            let expected = analyticPoint(c, at: c.startAngle)
            XCTAssertEqual(appleStart.x, expected.x, accuracy: 1e-6, "Apple start.x — \(c.label)")
            XCTAssertEqual(appleStart.y, expected.y, accuracy: 1e-6, "Apple start.y — \(c.label)")
            XCTAssertEqual(polylineStart.x, expected.x, accuracy: 1e-6, "Polyline start.x — \(c.label)")
            XCTAssertEqual(polylineStart.y, expected.y, accuracy: 1e-6, "Polyline start.y — \(c.label)")
        }
    }

    func testApplePathAndPolyfillPolylineEndPointsMatch() {
        for c in Self.cases {
            let appleEnd = lastPoint(of: applePath(for: c))
            let polylineEnd = lastPoint(of: polylinePath(for: c))
            let expected = analyticPoint(c, at: c.startAngle + c.arcAngle)
            XCTAssertEqual(appleEnd.x, expected.x, accuracy: 1e-6, "Apple end.x — \(c.label)")
            XCTAssertEqual(appleEnd.y, expected.y, accuracy: 1e-6, "Apple end.y — \(c.label)")
            XCTAssertEqual(polylineEnd.x, expected.x, accuracy: 1e-6, "Polyline end.x — \(c.label)")
            XCTAssertEqual(polylineEnd.y, expected.y, accuracy: 1e-6, "Polyline end.y — \(c.label)")
        }
    }

    func testBoundingBoxesMatchWithinChordTolerance() {
        for c in Self.cases {
            let appleBounds = applePath(for: c).cgPath.boundingBoxOfPath
            let polyBounds = polylinePath(for: c).cgPath.boundingBoxOfPath

            // 1° chord error on an ellipse of radius R is bounded by
            // ~R · (1 − cos(0.5°)) ≈ R · 3.8e-5. We allow 0.05 user units —
            // many orders of magnitude over the geometric error, but tight
            // enough to catch real divergence (the original T·R·S bug
            // produced hundreds-of-units drift).
            let r = Swift.max(c.w, c.h) / 2
            let tolerance = Swift.max(0.05, r * 1e-4)

            XCTAssertEqual(appleBounds.minX, polyBounds.minX, accuracy: tolerance, "minX — \(c.label)")
            XCTAssertEqual(appleBounds.minY, polyBounds.minY, accuracy: tolerance, "minY — \(c.label)")
            XCTAssertEqual(appleBounds.maxX, polyBounds.maxX, accuracy: tolerance, "maxX — \(c.label)")
            XCTAssertEqual(appleBounds.maxY, polyBounds.maxY, accuracy: tolerance, "maxY — \(c.label)")
        }
    }

    func testPolylineVerticesLieOnEllipse() {
        for c in Self.cases {
            let path = polylinePath(for: c)
            let points = allEndpoints(of: path)
            XCTAssertFalse(points.isEmpty, "Polyline empty — \(c.label)")

            // Every emitted polyline vertex must satisfy the ellipse
            // equation in the un-rotated, un-translated frame:
            //     ((p − c) · R⁻¹ / (rx, ry))² sum to 1.
            let cosA = cos(c.rotation)
            let sinA = sin(c.rotation)
            let rx = c.w / 2
            let ry = c.h / 2
            for (i, p) in points.enumerated() {
                let dx = p.x - c.cx
                let dy = p.y - c.cy
                let xs =  cosA * dx + sinA * dy
                let ys = -sinA * dx + cosA * dy
                let normSq = (xs / rx) * (xs / rx) + (ys / ry) * (ys / ry)
                XCTAssertEqual(normSq, 1, accuracy: 1e-6, "Vertex \(i) off-ellipse for \(c.label)")
            }
        }
    }

    func testApplePathInteriorLiesOnEllipse() {
        for c in Self.cases {
            let apple = applePath(for: c)
            let samples = densePathSamples(of: apple, samplesPerCurve: 50)
            XCTAssertFalse(samples.isEmpty, "Apple path empty — \(c.label)")

            let cosA = cos(c.rotation)
            let sinA = sin(c.rotation)
            let rx = c.w / 2
            let ry = c.h / 2
            for (i, p) in samples.enumerated() {
                let dx = p.x - c.cx
                let dy = p.y - c.cy
                let xs =  cosA * dx + sinA * dy
                let ys = -sinA * dx + cosA * dy
                let normSq = (xs / rx) * (xs / rx) + (ys / ry) * (ys / ry)
                XCTAssertEqual(normSq, 1, accuracy: 2e-3,
                    "Apple cubic sample \(i) off-ellipse for \(c.label) (normSq=\(normSq))")
            }
        }
    }

    func testApplePathAndPolylineHausdorffWithinTolerance() {
        for c in Self.cases {
            let apple = applePath(for: c)
            let poly = polylinePath(for: c)

            let appleSamples = densePathSamples(of: apple, samplesPerCurve: 50)
            let polylineSamples = allEndpoints(of: poly)
            let appleSegments = consecutivePairs(appleSamples)
            let polylineSegments = consecutivePairs(polylineSamples)

            XCTAssertFalse(appleSegments.isEmpty, "Apple has no segments — \(c.label)")
            XCTAssertFalse(polylineSegments.isEmpty, "Polyline has no segments — \(c.label)")

            let h_AtoP = appleSamples
                .map { p in polylineSegments.map { pointToSegmentDistance(p, $0.0, $0.1) }.min() ?? .infinity }
                .max() ?? 0
            let h_PtoA = polylineSamples
                .map { p in appleSegments.map { pointToSegmentDistance(p, $0.0, $0.1) }.min() ?? .infinity }
                .max() ?? 0
            let hausdorff = Swift.max(h_AtoP, h_PtoA)

            let r = Swift.max(c.w, c.h) / 2
            let tolerance = Swift.max(0.05, 0.005 * r)
            XCTAssertLessThan(hausdorff, tolerance,
                "Hausdorff \(hausdorff) exceeds tolerance \(tolerance) for \(c.label)")
        }
    }

    // MARK: - Helpers

    private func applePath(for c: ArcCase) -> MBezierPath {
        let path = MBezierPath()
        SVGPath.appendEllipticalArcViaTransform(
            to: path,
            cx: c.cx, cy: c.cy, w: c.w, h: c.h,
            rotation: c.rotation,
            startAngle: c.startAngle, arcAngle: c.arcAngle
        )
        return path
    }

    private func polylinePath(for c: ArcCase) -> MBezierPath {
        let path = MBezierPath()
        SVGPath.appendEllipticalArcAsPolyline(
            to: path,
            cx: c.cx, cy: c.cy, w: c.w, h: c.h,
            rotation: c.rotation,
            startAngle: c.startAngle, arcAngle: c.arcAngle
        )
        return path
    }

    private func analyticPoint(_ c: ArcCase, at angle: CGFloat) -> CGPoint {
        let cosA = cos(c.rotation)
        let sinA = sin(c.rotation)
        let xs = cos(angle) * (c.w / 2)
        let ys = sin(angle) * (c.h / 2)
        return CGPoint(x: c.cx + cosA * xs - sinA * ys, y: c.cy + sinA * xs + cosA * ys)
    }

    private func firstPoint(of path: MBezierPath) -> CGPoint {
        allEndpoints(of: path).first ?? .zero
    }

    private func lastPoint(of path: MBezierPath) -> CGPoint {
        allEndpoints(of: path).last ?? .zero
    }

    /// Collects the endpoint of every path element. On Apple this iterates
    /// CGPath via `applyWithBlock`; it works uniformly for paths made of
    /// move/line/quad/cubic segments.
    private func allEndpoints(of path: MBezierPath) -> [CGPoint] {
        var points: [CGPoint] = []
        path.cgPath.applyWithBlock { elemPtr in
            let elem = elemPtr.pointee
            switch elem.type {
            case .moveToPoint, .addLineToPoint:
                points.append(elem.points[0])
            case .addQuadCurveToPoint:
                points.append(elem.points[1])
            case .addCurveToPoint:
                points.append(elem.points[2])
            case .closeSubpath:
                break
            @unknown default:
                break
            }
        }
        return points
    }

    private static func quadBezier(_ p0: CGPoint, _ cp: CGPoint, _ p1: CGPoint, at t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let x = mt * mt * p0.x + 2 * mt * t * cp.x + t * t * p1.x
        let y = mt * mt * p0.y + 2 * mt * t * cp.y + t * t * p1.y
        return CGPoint(x: x, y: y)
    }

    private static func cubicBezier(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, at t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        let t2 = t * t
        let t3 = t2 * t
        let x = mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x
        let y = mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y
        return CGPoint(x: x, y: y)
    }

    /// Dense samples along every drawing element of `path`. Move/line endpoints
    /// produce 1 sample; quad/cubic curves produce `samplesPerCurve` interior
    /// samples (t ∈ (0, 1]) plus the starting endpoint is captured by the
    /// previous element. Used by both Apple-interior-on-ellipse and Hausdorff
    /// tests.
    private func densePathSamples(of path: MBezierPath, samplesPerCurve: Int) -> [CGPoint] {
        var samples: [CGPoint] = []
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        path.cgPath.applyWithBlock { elemPtr in
            let elem = elemPtr.pointee
            switch elem.type {
            case .moveToPoint:
                let p = elem.points[0]
                samples.append(p)
                current = p
                subpathStart = p
            case .addLineToPoint:
                let p = elem.points[0]
                samples.append(p)
                current = p
            case .addQuadCurveToPoint:
                let cp = elem.points[0]
                let next = elem.points[1]
                for i in 1...samplesPerCurve {
                    let t = CGFloat(i) / CGFloat(samplesPerCurve)
                    samples.append(Self.quadBezier(current, cp, next, at: t))
                }
                current = next
            case .addCurveToPoint:
                let cp1 = elem.points[0]
                let cp2 = elem.points[1]
                let next = elem.points[2]
                for i in 1...samplesPerCurve {
                    let t = CGFloat(i) / CGFloat(samplesPerCurve)
                    samples.append(Self.cubicBezier(current, cp1, cp2, next, at: t))
                }
                current = next
            case .closeSubpath:
                current = subpathStart
            @unknown default:
                break
            }
        }
        return samples
    }

    private func consecutivePairs(_ points: [CGPoint]) -> [(CGPoint, CGPoint)] {
        guard points.count >= 2 else { return [] }
        return (1..<points.count).map { (points[$0 - 1], points[$0]) }
    }

    private func pointToSegmentDistance(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lenSq = dx * dx + dy * dy
        if lenSq < 1e-12 {
            return hypot(p.x - a.x, p.y - a.y)
        }
        let t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq
        let clamped = Swift.min(Swift.max(t, 0), 1)
        let cx = a.x + clamped * dx
        let cy = a.y + clamped * dy
        return hypot(p.x - cx, p.y - cy)
    }
}
#endif

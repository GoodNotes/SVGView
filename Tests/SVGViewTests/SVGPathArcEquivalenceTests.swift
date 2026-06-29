import XCTest
@testable import SVGView

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
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
}

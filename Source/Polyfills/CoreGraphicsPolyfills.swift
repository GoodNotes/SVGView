//
//  CoreGraphicsPolyfills.swift
//  SVGView
//
//  Created by khoi on 10/5/25.
//

import Foundation

public typealias CGFloat = Foundation.CGFloat
public typealias CGSize = Foundation.CGSize

#if os(WASI) || os(Linux)
    private let KAPPA: CGFloat = 0.5522847498  // 4 *(sqrt(2) -1)/3

public struct CGAffineTransform: Equatable {
        public var a, b, c, d, tx, ty: CGFloat

        public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) {

            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.tx = tx
            self.ty = ty
        }
    }

    public enum CGLineJoin: UInt32 {

        case miter
        case round
        case bevel

        public init() { self = .miter }
    }

    public enum CGLineCap: UInt32 {

        case butt
        case round
        case square

        public init() { self = .butt }
    }

    /// A graphics path is a mathematical description of a series of shapes or lines.
    public struct CGPath {

        public typealias Element = PathElement

        public var elements: [Element]

        public init(elements: [Element] = []) {

            self.elements = elements
        }
    }

    // MARK: - Supporting Types

    /// A path element.
    public enum PathElement {

        /// The path element that starts a new subpath. The element holds a single point for the destination.
        case moveToPoint(CGPoint)

        /// The path element that adds a line from the current point to a new point.
        /// The element holds a single point for the destination.
        case addLineToPoint(CGPoint)

        /// The path element that adds a quadratic curve from the current point to the specified point.
        /// The element holds a control point and a destination point.
        case addQuadCurveToPoint(CGPoint, CGPoint)

        /// The path element that adds a cubic curve from the current point to the specified point.
        /// The element holds two control points and a destination point.
        case addCurveToPoint(CGPoint, CGPoint, CGPoint)

        /// The path element that closes and completes a subpath. The element does not contain any points.
        case closeSubpath
    }

    extension CGPath {

        public var boundingBoxOfPath: CGRect {
            var minX = CGFloat.infinity
            var minY = CGFloat.infinity
            var maxX = -CGFloat.infinity
            var maxY = -CGFloat.infinity
            
            for element in elements {
                switch element {
                case .moveToPoint(let point),
                        .addLineToPoint(let point):
                    minX = min(minX, point.x)
                    minY = min(minY, point.y)
                    maxX = max(maxX, point.x)
                    maxY = max(maxY, point.y)
                    
                case .addQuadCurveToPoint(let control, let point):
                    minX = min(minX, control.x, point.x)
                    minY = min(minY, control.y, point.y)
                    maxX = max(maxX, control.x, point.x)
                    maxY = max(maxY, control.y, point.y)
                    
                case .addCurveToPoint(let control1, let control2, let point):
                    minX = min(minX, control1.x, control2.x, point.x)
                    minY = min(minY, control1.y, control2.y, point.y)
                    maxX = max(maxX, control1.x, control2.x, point.x)
                    maxY = max(maxY, control1.y, control2.y, point.y)
                    
                case .closeSubpath:
                    break
                }
            }
            
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }

        public mutating func addRect(_ rect: CGRect) {

            let newElements: [Element] = [
                .moveToPoint(CGPoint(x: rect.minX, y: rect.minY)),
                .addLineToPoint(CGPoint(x: rect.maxX, y: rect.minY)),
                .addLineToPoint(CGPoint(x: rect.maxX, y: rect.maxY)),
                .addLineToPoint(CGPoint(x: rect.minX, y: rect.maxY)),
                .closeSubpath,
            ]

            elements.append(contentsOf: newElements)
        }

        public mutating func addEllipse(in rect: CGRect) {

            var p = CGPoint()
            var p1 = CGPoint()
            var p2 = CGPoint()

            let hdiff = rect.width / 2 * KAPPA
            let vdiff = rect.height / 2 * KAPPA

            p = CGPoint(x: rect.origin.x + rect.width / 2, y: rect.origin.y + rect.height)
            elements.append(.moveToPoint(p))

            p = CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height / 2)
            p1 = CGPoint(x: rect.origin.x + rect.width / 2 - hdiff, y: rect.origin.y + rect.height)
            p2 = CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height / 2 + vdiff)
            elements.append(.addCurveToPoint(p1, p2, p))

            p = CGPoint(x: rect.origin.x + rect.size.width / 2, y: rect.origin.y)
            p1 = CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height / 2 - vdiff)
            p2 = CGPoint(x: rect.origin.x + rect.size.width / 2 - hdiff, y: rect.origin.y)
            elements.append(.addCurveToPoint(p1, p2, p))

            p = CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height / 2)
            p1 = CGPoint(x: rect.origin.x + rect.size.width / 2 + hdiff, y: rect.origin.y)
            p2 = CGPoint(
                x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height / 2 - vdiff)
            elements.append(.addCurveToPoint(p1, p2, p))

            p = CGPoint(x: rect.origin.x + rect.size.width / 2, y: rect.origin.y + rect.size.height)
            p1 = CGPoint(
                x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height / 2 + vdiff)
            p2 = CGPoint(
                x: rect.origin.x + rect.size.width / 2 + hdiff, y: rect.origin.y + rect.size.height)
            elements.append(.addCurveToPoint(p1, p2, p))
        }

        public mutating func move(to point: CGPoint) {

            elements.append(.moveToPoint(point))
        }

        public mutating func addLine(to point: CGPoint) {

            elements.append(.addLineToPoint(point))
        }

        public mutating func addCurve(to endPoint: CGPoint, control1: CGPoint, control2: CGPoint) {

            elements.append(.addCurveToPoint(control1, control2, endPoint))
        }

        public mutating func addQuadCurve(to endPoint: CGPoint, control: CGPoint) {

            elements.append(.addQuadCurveToPoint(control, endPoint))
        }

        public mutating func closeSubpath() {

            elements.append(.closeSubpath)
        }
    }

    public struct CGPathElement {

        public var type: CGPathElementType

        public var points: (CGPoint, CGPoint, CGPoint)

        public init(type: CGPathElementType, points: (CGPoint, CGPoint, CGPoint)) {

            self.type = type
            self.points = points
        }
    }

    /// Rules for determining which regions are interior to a path.
    ///
    /// When filling a path, regions that a fill rule defines as interior to the path are painted.
    /// When clipping with a path, regions interior to the path remain visible after clipping.
    public enum CGPathFillRule: Int {

        /// A rule that considers a region to be interior to a path based on the number of times it is enclosed by path elements.
        case evenOdd

        /// A rule that considers a region to be interior to a path if the winding number for that region is nonzero.
        case winding
    }

    /// The type of element found in a path.
    public enum CGPathElementType {

        /// The path element that starts a new subpath. The element holds a single point for the destination.
        case moveToPoint

        /// The path element that adds a line from the current point to a new point.
        /// The element holds a single point for the destination.
        case addLineToPoint

        /// The path element that adds a quadratic curve from the current point to the specified point.
        /// The element holds a control point and a destination point.
        case addQuadCurveToPoint

        /// The path element that adds a cubic curve from the current point to the specified point.
        /// The element holds two control points and a destination point.
        case addCurveToPoint

        /// The path element that closes and completes a subpath. The element does not contain any points.
        case closeSubpath
    }

    extension CGPoint {
        
        @inline(__always)
        public func applying(_ t: CGAffineTransform) -> CGPoint {
            return CGPoint(x: t.a * x + t.c * y + t.tx,
                           y: t.b * x + t.d * y + t.ty)
        }
    }


    extension CGAffineTransform {
        public var isIdentity: Bool {
            self == CGAffineTransform.identity
        }
        
        public static var identity: CGAffineTransform {
            CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
        }
        
        public init(translationX tx: CGFloat, y ty: CGFloat) {
            self.init(a: 1, b: 0, c: 0, d: 1, tx: tx, ty: ty)
        }

        public init(scaleX sx: CGFloat, y sy: CGFloat) {
            self.init(a: sx, b: 0, c: 0, d: sy, tx: 0, ty: 0)
        }

        public init(rotationAngle angle: CGFloat) {
            self.init(a: cos(angle), b: sin(angle), c: -sin(angle), d: cos(angle), tx: 0, ty: 0)
        }
        
        public func translatedBy(x: CGFloat, y: CGFloat) -> CGAffineTransform {
            return self.concatenating(CGAffineTransform(translationX: x, y: y))
        }
        
        public func concatenating(_ t: CGAffineTransform) -> CGAffineTransform {
            return CGAffineTransform(
                a: a * t.a + c * t.b,
                b: b * t.a + d * t.b,
                c: a * t.c + c * t.d,
                d: b * t.c + d * t.d,
                tx: a * t.tx + c * t.ty + tx,
                ty: b * t.tx + d * t.ty + ty
            )
        }
        
        public func scaledBy(x: CGFloat, y: CGFloat) -> CGAffineTransform {
            return self.concatenating(CGAffineTransform(scaleX: x, y: y))
        }
        
        public func rotated(by angle: CGFloat) -> CGAffineTransform {
            return self.concatenating(CGAffineTransform(rotationAngle: angle))
        }
    }
#else
import CoreGraphics
public typealias CGLineJoin = CoreGraphics.CGLineJoin
public typealias CGLineCap = CoreGraphics.CGLineCap
public typealias CGPathFillRule = CoreGraphics.CGPathFillRule
public typealias CGPath = CoreGraphics.CGPath
public typealias CGAffineTransform = CoreGraphics.CGAffineTransform
#endif

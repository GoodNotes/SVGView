//
//  MBezierPath+Extension_macOS.swift
//  Macaw
//
//  Created by Daniil Manin on 8/17/17.
//  Copyright © 2017 Exyte. All rights reserved.
//

#if os(OSX)
import Foundation
import AppKit
extension MBezierPath {

    
    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)

        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)

            switch type {
            case .moveTo:
                path.move(to: CGPoint(x: points[0].x, y: points[0].y))

            case .lineTo:
                path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))

            case .curveTo:
                path.addCurve(
                    to: CGPoint(x: points[2].x, y: points[2].y),
                    control1: CGPoint(x: points[0].x, y: points[0].y),
                    control2: CGPoint(x: points[1].x, y: points[1].y))

            case .closePath:
                path.closeSubpath()
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            @unknown default:
                fatalError("Type of element undefined")
            }
        }

        return path
    }

    public convenience init(arcCenter center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        self.init()
        self.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
    }


    func addLine(to: NSPoint) {
        self.line(to: to)
    }

    func addCurve(to: NSPoint, controlPoint1: NSPoint, controlPoint2: NSPoint) {
        self.curve(to: to, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }

    func addQuadCurve(to: NSPoint, controlPoint: NSPoint) {
        let QP0 = self.currentPoint
        let CP3 = to

        let CP1 = CGPoint(
            x: QP0.x + ((2.0 / 3.0) * (controlPoint.x - QP0.x)),
            y: QP0.y + ((2.0 / 3.0) * (controlPoint.y - QP0.y))
        )

        let CP2 = CGPoint(
            x: to.x + (2.0 / 3.0) * (controlPoint.x - to.x),
            y: to.y + (2.0 / 3.0) * (controlPoint.y - to.y)
        )

        self.addCurve(to: CP3, controlPoint1: CP1, controlPoint2: CP2)
    }

    func addArc(withCenter: NSPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        let startAngleRadian = ((startAngle) * (180.0 / .pi))
        let endAngleRadian = ((endAngle) * (180.0 / .pi))
        self.appendArc(withCenter: withCenter, radius: radius, startAngle: startAngleRadian, endAngle: endAngleRadian, clockwise: !clockwise)
    }

    
    func apply(_ transform: CGAffineTransform) {
        let affineTransform = AffineTransform(
            m11: transform.a,
            m12: transform.b,
            m21: transform.c,
            m22: transform.d,
            tX: transform.tx,
            tY: transform.ty
        )

        self.transform(using: affineTransform)
    }
}

#endif

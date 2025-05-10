//
//  CoreGraphicsPolyfills.swift
//  SVGView
//
//  Created by khoi on 10/5/25.
//

import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
public typealias CGAffineTransform = CoreGraphics.CGAffineTransform
public typealias CGLineJoin = CoreGraphics.CGLineJoin
public typealias CGLineCap = CoreGraphics.CGLineCap
public typealias CGFloat = Foundation.CGFloat
public typealias CGPathFillRule = CoreGraphics.CGPathFillRule
#else
extension CGAffineTransform {
    public static var identity: CGAffineTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
}
#endif

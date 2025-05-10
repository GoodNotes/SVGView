//
//  CoreGraphicsPolyfills.swift
//  SVGView
//
//  Created by khoi on 10/5/25.
//

import Foundation
public typealias CGFloat = Foundation.CGFloat

#if canImport(CoreGraphics)
import CoreGraphics
public typealias CGAffineTransform = CoreGraphics.CGAffineTransform
public typealias CGLineJoin = CoreGraphics.CGLineJoin
public typealias CGLineCap = CoreGraphics.CGLineCap
public typealias CGPathFillRule = CoreGraphics.CGPathFillRule
#else
public struct CGAffineTransform {    
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
#endif

public extension CGAffineTransform {
    static var identity: CGAffineTransform { CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0) }
}

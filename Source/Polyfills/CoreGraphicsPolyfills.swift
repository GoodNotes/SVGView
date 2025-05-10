//
//  CoreGraphicsPolyfills.swift
//  SVGView
//
//  Created by khoi on 10/5/25.
//

import Foundation

#if !canImport(CoreGraphics)
extension CGAffineTransform {
    public static var identity: CGAffineTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
}
#endif

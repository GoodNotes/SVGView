//
//  SVGParserExtensions.swift
//  SVGView
//
//  Created by Yuri Strot on 25.05.2022.
//

#if FOUNDATION_ESSENTIALS_BUILD
import FoundationEssentials
#elseif canImport(CoreGraphics)
import CoreGraphics
#else
import Foundation
#endif

extension CGFloat {
    var degreesToRadians: CGFloat {
        return self * .pi / 180
    }

}

extension String {

    var cgFloatValue: CGFloat? {
        if let value = Double(self) {
            return CGFloat(value)
        }
        return .none
    }
}

extension CGAffineTransform {

    func shear(shx: CGFloat = 0, shy: CGFloat = 0) -> CGAffineTransform {
        return CGAffineTransform(a: a + c * shy, b: b + d * shy,
                                 c: a * shx + c, d: b * shx + d, tx: tx, ty: ty)
    }

}

extension Dictionary where Key == String {

    subscript(ignoreCase key: Key) -> Value? {
        get {
            if let k = keys.first(where: { $0.lowercased() == key.lowercased() }) {
                return self[k]
            }
            return nil
        }
    }

}

//
//  Extensions.swift
//  SVGView
//
//  Created by Yuriy Strot on 18.01.2021.
//

#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
#endif

extension Bool: SerializableAtom {

    public func serialize() -> String {
        return self.description
    }

}

extension String: SerializableAtom {

    func serialize() -> String {
        return "\"\(self.replacingOccurrences(of: "\"", with: "\\\""))\""
    }

}

extension CGFloat: SerializableAtom {

    func serialize() -> String {
        let s = self.description
        return s.hasSuffix(".0") ? String(s[s.startIndex..<s.index(s.endIndex, offsetBy: -2)]) : s
    }

}

extension Double: SerializableAtom {

    func serialize() -> String {
        return CGFloat(self).serialize()
    }

}

extension CGAffineTransform: SerializableAtom {

    func serialize() -> String {
        let nums = [a, b, c, d, tx, ty]
        return "[\(nums.map{String(format: "%.10f", $0)}.joined(separator: ", "))]"
    }
}

extension CGRect: SerializableBlock {

    func serialize(_ serializer: Serializer) {
        serializer.add("x", self.minX, 0).add("y", self.minY, 0)
        serializer.add("width", self.width, 0).add("height", self.height, 0)
    }

}

extension Collection where Iterator.Element == CGPoint {

    var serialized: CGPointList? {
        if self.isEmpty {
            return nil
        }
        return CGPointList(points: self.map { $0 })
    }

}

class CGPointList: SerializableAtom {
    
    let points: [CGPoint]
    
    init(points: [CGPoint]) {
        self.points = points
    }

    func serialize() -> String {
        return "[\(points.map { p in "\(p.x.serialize()), \(p.y.serialize())" }.joined(separator: ", "))]"
    }

}

extension Collection where Iterator.Element == CGFloat {

    var serialized: CGFloatList? {
        if self.isEmpty {
            return nil
        }
        return CGFloatList(list: self.map { $0 })
    }

}

class CGFloatList: SerializableAtom {

    let list: [CGFloat]

    init(list: [CGFloat]) {
        self.list = list
    }

    func serialize() -> String {
        return "[\(list.map { p in p.serialize() }.joined(separator: ", "))]"
    }

}

extension CGLineCap: SerializableOption {

    func isDefault() -> Bool {
        return self == .butt
    }

    func serialize() -> String {
        switch self {
        case .round:
            return "round"
        case .square:
            return "square"
        default:
            return "butt"
        }
    }

}

extension CGLineJoin: SerializableOption {

    func isDefault() -> Bool {
        return self == .miter
    }

    func serialize() -> String {
        switch self {
        case .round:
            return "round"
        case .bevel:
            return "bevel"
        default:
            return "miter"
        }
    }

}

extension CGPathFillRule: SerializableOption {

    func isDefault() -> Bool {
        return self == .winding
    }

    func serialize() -> String {
        switch self {
        case .evenOdd:
            return "evenodd"
        default:
            return "nonzero"
        }
    }

}

extension SVGText.Anchor: SerializableOption {

    func isDefault() -> Bool {
        return self == .leading
    }

    func serialize() -> String {
        switch self {
        case .center:
            return "middle"
        case .trailing:
            return "end"
        default:
            return "start"
        }
    }

}

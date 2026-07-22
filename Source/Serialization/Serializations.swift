//
//  Extensions.swift
//  SVGView
//
//  Created by Yuriy Strot on 18.01.2021.
//

#if canImport(SwiftUI)
import SwiftUI
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension Bool: SerializableAtom {

    public func serialize() -> String {
        return self.description
    }

}

extension String: SerializableAtom {

    func serialize() -> String {
        var escaped = String()
        escaped.reserveCapacity(count)

        for character in self {
            if character == "\"" {
                escaped.append("\\\"")
            } else {
                escaped.append(character)
            }
        }

        return "\"\(escaped)\""
    }

}

extension CGFloat: SerializableAtom {

    func serialize() -> String {
        let s = self.description
        return s.hasSuffix(".0") ? String(s[s.startIndex..<s.index(s.endIndex, offsetBy: -2)]) : s
    }

}

#if !canImport(FoundationEssentialsExtras)
extension Double: SerializableAtom {

    func serialize() -> String {
        return CGFloat(self).serialize()
    }

}
#endif

private enum SVGPortableDecimalFormatter {
    private static let maxFractionDigits = 10
    private static let scale: Double = 10_000_000_000.0
    private static let scaleInteger: UInt64 = 10_000_000_000

    static func string(for value: Double) -> String {
        let rounded = (value * scale).rounded() / scale
        if rounded == 0 {
            return "0"
        }
        if !rounded.isFinite {
            return rounded.description
        }

        let sign = rounded < 0 ? "-" : ""
        let absoluteValue = Swift.abs(rounded)
        if absoluteValue >= Double(UInt64.max) {
            let fallback = rounded.description
            return fallback.hasSuffix(".0")
                ? String(fallback.dropLast(2))
                : fallback
        }
        var integerPart = UInt64(absoluteValue.rounded(.towardZero))
        var fractionalPart = UInt64(((absoluteValue - Double(integerPart)) * scale).rounded())

        if fractionalPart == scaleInteger {
            integerPart += 1
            fractionalPart = 0
        }

        if fractionalPart == 0 {
            return "\(sign)\(integerPart)"
        }

        var fraction = String(fractionalPart)
        if fraction.count < maxFractionDigits {
            fraction = String(repeating: "0", count: maxFractionDigits - fraction.count) + fraction
        }

        while fraction.last == "0" {
            fraction.removeLast()
        }

        return "\(sign)\(integerPart).\(fraction)"
    }
}

extension CGAffineTransform: SerializableAtom {

    func serialize() -> String {
        let nums = [a, b, c, d, tx, ty]
        return "[\(nums.map { SVGPortableDecimalFormatter.string(for: Double($0)) }.joined(separator: ", "))]"
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

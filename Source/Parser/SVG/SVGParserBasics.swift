//
//  ColorExtension.swift
//  SVGView
//
//  Created by Alisa Mylnikova on 17/07/2020.
//

#if canImport(SwiftUI)
import SwiftUI
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension SVGHelper {

  static func parseDouble(_ attributes: [String: String], _ key: String, alternativeKeys: [String] = [], defaultValue: Double = 0) -> Double {
        if let value = attributes[key], let result = doubleFromString(value) {
            return result
        }
        for alternativeKey in alternativeKeys {
            if let value = attributes[alternativeKey], let result = doubleFromString(value) {
                return result
            }
        }
        return defaultValue
    }

    static func parseCGFloat(_ attributes: [String: String], _ key: String, defaultValue: CGFloat = 0) -> CGFloat {
        if let value = attributes[key], let result = doubleFromString(value) {
            return CGFloat(result)
        }
        return defaultValue
    }

    static func doubleFromString(_ string: String) -> Double? {
        if string == "none" {
            return 0
        }

        guard let parsed = SVGNumberParser.numberAndUnit(from: string) else {
            return nil
        }

        switch parsed.unit {
        case nil, "px":
            return parsed.value
        default:
            print("SVG parsing error. Unit \"\(parsed.unit ?? "")\" is not supported")
            return parsed.value
        }
    }

    static func parsePointsArray(_ string: String) -> [CGPoint] {
        let numbers = SVGNumberParser.numbers(in: string)

        var points: [CGPoint] = []
        var i = 0
        while i < numbers.count - 1 {
            points.append(CGPoint(x: numbers[i], y: numbers[i + 1]))
            i += 2
        }

        return points
    }

    static func parseOpacity(_ attributes: [String: String], _ key: String, alternativeKeys: [String] = []) -> Double {
        let opacity = parseDouble(attributes, key, alternativeKeys: alternativeKeys, defaultValue: 1)
        return min(max(opacity, 0), 1)
    }

    static func parseFill(_ style: [String: String], _ index: SVGIndex) -> SVGPaint? {
        guard let colorString = style["fill"] else {
            return SVGColor.black.opacity(parseOpacity(style, "fill-opacity", alternativeKeys: ["opacity"]))
        }
        return parseFillInternal(colorString, style, index)
    }

    static func parseStrokeFill(_ style: [String: String], _ index: SVGIndex) -> SVGPaint? {
        guard let colorString = style["stroke"] else {
            return .none
        }
        return parseFillInternal(colorString, style, index)
    }

    static func parseFillInternal(_ colorString: String, _ style: [String: String], _ index: SVGIndex) -> SVGPaint? {
        if let colorId = SVGHelper.parseIdFromUrl(colorString) {
            if let paint = index.paint(by: colorId) {
                return paint
            }
        }
        if let color = parseColor(colorString, style) {
            return color.opacity(color.opacity * parseOpacity(style, "fill-opacity", alternativeKeys: ["opacity"]))
        }
        
        return .none
    }

    static func parseColor(_ string: String, _ style: [String: String]) -> SVGColor? {
        let normalized = SVGStringUtilities.removingWhitespace(from: string)
        if normalized == "none" || normalized == "transparent" {
            return .none
        } else if normalized == "currentColor", let currentColor = style["color"] {
            return parseColor(currentColor, style)
        } else if let defaultColor = SVGColor.by(name: normalized) {
            return defaultColor
        } else if normalized.hasPrefix("rgb") {
            return parseRGBANotation(colorString: normalized)
        } else {
            return createColorFromHex(normalized)
        }
    }

    static func createColorFromHex(_ hexString: String) -> SVGColor {
        var cleanedHexString = hexString
        if hexString.hasPrefix("#") {
            cleanedHexString = String(hexString.dropFirst())
        }
        if cleanedHexString.count == 3 {
            let x = Array(cleanedHexString)
            cleanedHexString = "\(x[0])\(x[0])\(x[1])\(x[1])\(x[2])\(x[2])"
        }
        return SVGColor(hex: cleanedHexString).opacity(1.0)
    }

    static func parseRGBANotation(colorString: String) -> SVGColor {
        let fromIndex = colorString.hasPrefix("rgba") ? 5 : 4
        let from = colorString.index(colorString.startIndex, offsetBy: fromIndex)
        let inPercentage = colorString.contains("%")
        let sp = SVGStringUtilities.removing(
            from: String(colorString.suffix(from: from))
        ) { character in
            character == "%" || character == ")" || character.isWhitespace
        }
        let x = sp.split(separator: ",").map(String.init)
        var red = 0.0
        var green = 0.0
        var blue = 0.0
        var alpha = 1.0 // Default to fully opaque, always from 0 to 1 in CSS
        if x.count >= 3 {
            if let r = Double(x[0]), let g = Double(x[1]), let b = Double(x[2]) {
                blue = b
                green = g
                red = r
            }
        }
        if x.count == 4, let a = Double(x[3]) {
            alpha = a
        }
        if inPercentage {
            red *= 2.55
            green *= 2.55
            blue *= 2.55
            if x.count == 4 {
                alpha *= 0.01
            }
        }
        return SVGColor(
            r: Int(red.rounded()),
            g: Int(green.rounded()),
            b: Int(blue.rounded())
        ).opacity(min(max(alpha, 0.0), 1.0))
    }

    static private func parseIdFromUrl(_ urlString: String) -> String? {
        SVGStringUtilities.stripURLIdentifier(urlString)
    }

}

//
//  SVGParserPrimitives.swift
//  SVGView
//
//  Created by Alisa Mylnikova on 20/07/2020.
//

#if FOUNDATION_ESSENTIALS_BUILD
import FoundationEssentials
import WASILibc
#elseif os(WASI) || os(Linux) || os(Android)
import Foundation
#else
import SwiftUI
#endif

public enum SVGHelper {

    static func parseUse(_ use: String?) -> String? {
        guard let use else {
            return nil
        }
        return SVGStringUtilities.stripURLIdentifier(use) ?? use
    }

    static func parseId(_ dict: [String: String]) -> String? {
        return dict["id"] ?? dict["xml:id"]
    }

    static func parseMarkerInAttribute(_ dict: [String: String], key: String) -> String? {
        guard let markerId = dict[key] else {
            return .none
        }
        return SVGStringUtilities.stripURLIdentifier(markerId)
    }

    static func parseStroke(_ style: [String: String], index: SVGIndex) -> SVGStroke? {
        guard let fill = SVGHelper.parseStrokeFill(style, index) else {
            return .none
        }

        return SVGStroke(
            fill: fill.opacity(SVGHelper.parseOpacity(style, "stroke-opacity", alternativeKeys: ["opacity"])),
            width: parseCGFloat(style, "stroke-width", defaultValue: 1),
            cap: getStrokeCap(style),
            join: getStrokeJoin(style),
            miterLimit: parseCGFloat(style, "stroke-miterlimit", defaultValue: 4),
            dashes: getStrokeDashes(style),
            offset: parseCGFloat(style, "stroke-dashoffset"))
    }

    static func getStrokeDashes(_ style: [String: String]) -> [CGFloat] {
        var dashes = [CGFloat]()
        if let strokeDashes = style["stroke-dasharray"] {
            let separatedValues = SVGStringUtilities.split(strokeDashes) {
                $0.isWhitespace || $0 == ","
            }
            separatedValues.forEach { value in
                if let doubleValue = doubleFromString(value) {
                    dashes.append(CGFloat(doubleValue))
                }
            }
        }
        return dashes
    }

    static func getStrokeCap(_ style: [String: String]) -> CGLineCap {
        if let strokeCap = style["stroke-linecap"] {
            switch strokeCap {
            case "round":
                return .round
            case "square":
                return .square
            default:
                break
            }
        }
        return .butt
    }

    static func getStrokeJoin(_ style: [String: String]) -> CGLineJoin {
        if let strokeJoin = style["stroke-linejoin"] {
            switch strokeJoin {
            case "round":
                return .round
            case "bevel":
                return .bevel
            default:
                break
            }
        }
        return .miter
    }

    static func parseTransform(_ attributes: String, transform: CGAffineTransform = CGAffineTransform.identity) -> CGAffineTransform {
        let operations = SVGTransformParser.operations(in: attributes)
        guard !operations.isEmpty else {
            return transform
        }

        var finalTransform = transform
        for operation in operations {
            func value(at index: Int) -> CGFloat? {
                guard operation.values.indices.contains(index) else {
                    return nil
                }
                return CGFloat(operation.values[index])
            }

            switch operation.name {
            case "translate":
                if let x = value(at: 0) {
                    let y = value(at: 1) ?? 0
                    finalTransform = finalTransform.translatedBy(x: x, y: y)
                }
            case "scale":
                if let x = value(at: 0) {
                    let y = value(at: 1) ?? x
                    finalTransform = finalTransform.scaledBy(x: x, y: y)
                }
            case "rotate":
                if let angle = value(at: 0) {
                    if operation.values.count == 1 {
                        finalTransform = finalTransform.rotated(by: angle.degreesToRadians)
                    } else if operation.values.count == 3, let x = value(at: 1), let y = value(at: 2) {
                        finalTransform = finalTransform
                            .translatedBy(x: x, y: y)
                            .rotated(by: angle.degreesToRadians)
                            .translatedBy(x: 0 - x, y: 0 - y)
                    }
                }
            case "skewX":
                if let x = value(at: 0) {
                    let v = tan((x * .pi) / 180.0)
                    finalTransform = finalTransform.shear(shx: v, shy: 0)
                }
            case "skewY":
                if let y = value(at: 0) {
                    let v = tan((y * .pi) / 180.0)
                    finalTransform = finalTransform.shear(shx: 0, shy: v)
                }
            case "matrix":
                guard operation.values.count == 6,
                      let a = value(at: 0),
                      let b = value(at: 1),
                      let c = value(at: 2),
                      let d = value(at: 3),
                      let tx = value(at: 4),
                      let ty = value(at: 5) else {
                    continue
                }
                let transformMatrix = CGAffineTransform(
                    a: a,
                    b: b,
                    c: c,
                    d: d,
                    tx: tx,
                    ty: ty
                )
                finalTransform = finalTransform.concatenating(transformMatrix)
            default:
                break
            }
        }
        return finalTransform
    }

    static func transformForNodeInRespectiveCoords(respective: SVGNode, absolute: SVGNode) -> CGAffineTransform {
        let absoluteBounds = absolute.bounds()
        let respectiveBounds = respective.bounds()
        let finalSize = CGSize(width: absoluteBounds.width * respectiveBounds.width,
                               height: absoluteBounds.height * respectiveBounds.height)
        let scale = SVGPreserveAspectRatio(scaling: .none).layout(size: respectiveBounds.size, into: finalSize)
        let move = CGAffineTransform(translationX: absoluteBounds.minX, y: absoluteBounds.minY)
        return scale.concatenating(move)
    }

    static func parseViewPort(_ attributes: [String: String], context: SVGContext) -> CGRect? {
        if let widthAttr = attributes[ignoreCase: "width"],
                  let heightAttr = attributes[ignoreCase: "height"],
                  let width = SVGLengthParser.xAxis.double(string: widthAttr, context: context),
                  let height = SVGLengthParser.yAxis.double(string: heightAttr, context: context) {
          return CGRect(x: 0.0, y: 0.0, width: width, height: height)
        }
        return nil
    }

    static func parseViewBox(_ attributes: [String: String], context: SVGContext) -> CGRect? {
        // TODO: temporary solution, all attributes should be case insensitive
        if let string = attributes[ignoreCase: "viewBox"] {
            let nums = SVGNumberParser.numbers(in: string)
            if nums.count == 4 {
                return CGRect(x: nums[0], y: nums[1], width: nums[2], height: nums[3])
            }
        }
        return nil
    }

    static func parseDimension(_ attributes: [String: String], _ key: String) -> SVGLength? {
        guard let string = attributes[key] else {
            return .none
        }
        if string.hasSuffix("%"), let value = Double(string.dropLast()) {
            return SVGLength(percent: CGFloat(value))
        }
        if let value = Double(string) {
            return SVGLength(pixels: CGFloat(value))
        }
        return .none
    }

    static func parsePreserveAspectRatio(string: String?, context: SVGContext, defaultValue: SVGPreserveAspectRatio) -> SVGPreserveAspectRatio {
        if let contentModeString = string {
            let strings = SVGStringUtilities.split(contentModeString, where: \.isWhitespace)
            if strings.count == 1 { // none
                return SVGPreserveAspectRatio(scaling: parseScaling(strings[0]))
            }
            guard strings.count == 2 else {
                context.log(message: "Invalid content mode \(contentModeString)")
                return SVGPreserveAspectRatio()
            }

            let alignString = strings[0]
            var xAlign = alignString.prefix(4).lowercased()
            xAlign.remove(at: xAlign.startIndex)
            let xAligningMode = parseAlign(xAlign)

            var yAlign = alignString.suffix(4).lowercased()
            yAlign.remove(at: yAlign.startIndex)
            let yAligningMode = parseAlign(yAlign)

            let scalingMode = parseScaling(strings[1])
            return SVGPreserveAspectRatio(scaling: scalingMode, xAlign: xAligningMode, yAlign: yAligningMode)
        }
        return SVGPreserveAspectRatio(scaling: parseScaling("xMidYMid"))
    }

    static func parseAlign(_ string: String) -> SVGPreserveAspectRatio.Align {
        switch string {
            case "min": return .min
            case "max": return .max
            default: return .mid
        }
    }

    static func parseScaling(_ string: String) -> SVGPreserveAspectRatio.Scaling {
        switch string {
            case "meet": return .meet
            case "slice": return .slice
            default: return .none
        }
    }
}

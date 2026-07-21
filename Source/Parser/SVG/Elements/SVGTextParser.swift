//
//  SVGTextParser.swift
//  SVGView
//
//  Created by Yuri Strot on 29.05.2022.
//

#if FOUNDATION_ESSENTIALS_BUILD
import FoundationEssentials
#elseif os(WASI) || os(Linux) || os(Android)
import Foundation
#else
import SwiftUI
#endif

class SVGTextParser: SVGBaseElementParser {
    override func doParse(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> SVGNode? {
        let fontName = context.style("font-family") ?? "Serif"
        let fontSize = context.value(.fontSize)
        let fontWeight = context.style("font-weight") ?? "normal"
        let font = SVGFont(name: fontName, size: fontSize, weight: fontWeight)
        let textAnchor = parseTextAnchor(context.style("text-anchor"))

        let x = SVGHelper.parseCGFloat(context.properties, "x")
        let y = SVGHelper.parseCGFloat(context.properties, "y")
        let transform = CGAffineTransform(translationX: x, y: y)

        if let textNode = context.element.contents.first as? XMLText {
            let trimmed = SVGStringUtilities.collapsingWhitespace(
                in: SVGStringUtilities.trimmed(textNode.text)
            )
            return SVGText(text: trimmed, font: font, fill: SVGHelper.parseFill(context.styles, context.index), stroke: SVGHelper.parseStroke(context.styles, index: context.index), textAnchor: textAnchor, transform: transform)
        }
        return .none
    }

    private func parseTextAnchor(_ string: String?) -> SVGText.Anchor {
        if let anchor = string {
            if anchor == "middle" {
                return .center
            } else if anchor == "end" {
                return .trailing
            }
        }
        return .leading
    }
}

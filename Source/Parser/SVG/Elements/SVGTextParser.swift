//
//  SVGTextParser.swift
//  SVGView
//
//  Created by Yuri Strot on 29.05.2022.
//

#if os(WASI) || os(Linux)
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
        let translation = CGAffineTransform(translationX: x, y: y)

        var nodes: [SVGNode] = []
        for content in context.element.contents {
            if let textNode = content as? XMLText {
                let trimmed = textNode.text.trimmingCharacters(in: .whitespacesAndNewlines).processingWhitespaces()
                if !trimmed.isEmpty {
                    let node = SVGText(
                        text: trimmed,
                        font: font,
                        fill: SVGHelper.parseFill(context.styles, context.index),
                        stroke: SVGHelper.parseStroke(
                            context.styles,
                            index: context.index
                        ),
                        textAnchor: textAnchor,
                        transform: .identity
                    )
                    nodes.append(node)
                }
            } else if let element = content as? XMLElement, element.name == "tspan" {
                if let childNode = delegate(element) {
                    nodes.append(childNode)
                }
            }
        }
        guard !nodes.isEmpty else { return nil }
        if nodes.count == 1, let single = nodes.first as? SVGText {
            single.transform = translation.concatenating(single.transform)
            return single
        }
        return SVGGroup(contents: nodes, transform: translation)
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

    static var whitespaceRegex = try! NSRegularExpression(pattern: "\\s+", options: NSRegularExpression.Options.caseInsensitive)

}

extension String {

    fileprivate func processingWhitespaces() -> String {
        let range = NSMakeRange(0, self.count)
        let modString = SVGTextParser.whitespaceRegex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: " ")
        return modString
    }
}

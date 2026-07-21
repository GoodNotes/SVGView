//
//  SVGFontSizeAttribute.swift
//  SVGView
//
//  Created by Yuri Strot on 29.05.2022.
//

#if FOUNDATION_ESSENTIALS_BUILD
import FoundationEssentials
#else
import Foundation
#endif

class SVGFontSizeAttribute: SVGDefaultAttribute<CGFloat> {

    override var name: String { "font-size" }

    override var isInherited: Bool { true }

    override func parse(string: String, context: SVGNodeContext) -> CGFloat? {
        SVGLengthParser.fontSize.float(string: string, context: context)
    }

    override func defaultValue(context: SVGNodeContext) -> CGFloat {
        context.defaultFontSize
    }

}

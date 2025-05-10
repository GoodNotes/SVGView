

import Foundation
public class SVGText: SVGNode {
    public enum Anchor: String, SerializableEnum {
        case start
        case middle
        case end
    }
    
    public var text: String
    public var font: SVGFont?
    public var fill: SVGPaint?
    public var stroke: SVGStroke?
    public var textAnchor: Anchor

    public init(
        text: String,
        font: SVGFont? = nil,
        fill: SVGPaint? = SVGColor.black,
        stroke: SVGStroke? = nil,
        textAnchor: Anchor = .start,
        transform: CGAffineTransform = .identity,
        opaque: Bool = true,
        opacity: Double = 1,
        clip: SVGUserSpaceNode? = nil,
        mask: SVGNode? = nil
    ) {
        self.text = text
        self.font = font
        self.fill = fill
        self.stroke = stroke
        self.textAnchor = textAnchor
        super.init(transform: transform, opaque: opaque, opacity: opacity, clip: clip, mask: mask)
    }

    override func serialize(_ serializer: Serializer) {
        serializer.add("text", text).add("font", font).add("textAnchor", textAnchor)
        fill?.serialize(key: "fill", serializer: serializer)
        serializer.add("stroke", stroke)
        super.serialize(serializer)
    }
    
}

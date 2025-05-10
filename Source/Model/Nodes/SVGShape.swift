
import Foundation
public class SVGShape: SVGNode {

    public var fill: SVGPaint?
    public var stroke: SVGStroke?

    override func serialize(_ serializer: Serializer) {
        fill?.serialize(key: "fill", serializer: serializer)
        serializer.add("stroke", stroke)
        super.serialize(serializer)
    }
}

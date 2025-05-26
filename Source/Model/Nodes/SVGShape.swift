#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
import Combine
#endif

public class SVGShape: SVGNode {

#if os(WASI) || os(Linux)
    public var fill: SVGPaint?
    public var stroke: SVGStroke?
    public var markerStart: String?
    public var markerEnd: String?
#else
    @Published public var fill: SVGPaint?
    @Published public var stroke: SVGStroke?
    @Published public var markerStart: String?
    @Published public var markerEnd: String?
#endif

    override func serialize(_ serializer: Serializer) {
        fill?.serialize(key: "fill", serializer: serializer)
        serializer.add("stroke", stroke)
        serializer.add("marker-start", markerStart)
        serializer.add("marker-end", markerEnd)
        super.serialize(serializer)
    }
}

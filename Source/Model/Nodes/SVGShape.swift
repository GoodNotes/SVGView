#if os(WASI)
import Foundation
#else
import SwiftUI
import Combine
#endif

public class SVGShape: SVGNode {

    @Published public var fill: SVGPaint?
    @Published public var stroke: SVGStroke?

    override func serialize(_ serializer: Serializer) {
        fill?.serialize(key: "fill", serializer: serializer)
        serializer.add("stroke", stroke)
        super.serialize(serializer)
    }
}

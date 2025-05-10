
import Foundation
import CoreGraphics

public class SVGPath: SVGShape {
    

    public var segments: [PathSegment]
    public var fillRule: CGPathFillRule

    public init(segments: [PathSegment] = [], fillRule: CGPathFillRule = .winding) {
        self.segments = segments
        self.fillRule = fillRule
    }

    override public func frame() -> CGRect {
        toBezierPath().cgPath.boundingBoxOfPath
    }

    override public func bounds() -> CGRect {
        frame()
    }

    override func serialize(_ serializer: Serializer) {
        let path = segments.map { s in "\(s.type)\(s.data.compactMap { $0.serialize() }.joined(separator: ","))" }.joined(separator: " ")
        serializer.add("path", path)
        serializer.add("fillRule", fillRule)
        super.serialize(serializer)
    }

}

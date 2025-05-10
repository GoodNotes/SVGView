
import Foundation
public class SVGPolygon: SVGShape {

    public var points: [CGPoint]

    public init(_ points: [CGPoint]) {
        self.points = points
    }

    public init(points: [CGPoint] = []) {
        self.points = points
    }

    override public func frame() -> CGRect {
        guard !points.isEmpty else {
            return .zero
        }

        var minX = CGFloat(Int16.max)
        var minY = CGFloat(Int16.max)
        var maxX = CGFloat(Int16.min)
        var maxY = CGFloat(Int16.min)

        for point in points {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }

        return CGRect(x: minX, y: minY,
                      width: maxX - minX,
                      height: maxY - minY)
    }

    public override func bounds() -> CGRect {
        let frame = frame()
        return CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
    }

    override func serialize(_ serializer: Serializer) {
        serializer.add("points", points.serialized)
        super.serialize(serializer)
    }

}



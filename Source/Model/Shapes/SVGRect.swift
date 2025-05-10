
import Foundation
public class SVGRect: SVGShape {

    public var x: CGFloat
    public var y: CGFloat
    public var width: CGFloat
    public var height: CGFloat
    public var rx: CGFloat = 0
    public var ry: CGFloat = 0

    public init(x: CGFloat = 0, y: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0, rx: CGFloat = 0, ry: CGFloat = 0) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rx = rx
        self.ry = ry
    }

    public init(_ rect: CGRect) {
        self.x = rect.minX
        self.y = rect.minY
        self.width = rect.width
        self.height = rect.height
    }

    override public func frame() -> CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    override func serialize(_ serializer: Serializer) {
        serializer.add("x", x, 0).add("y", y, 0).add("width", width, 0).add("height", height, 0)
        serializer.add("rx", rx, 0).add("ry", ry, 0)
        super.serialize(serializer)
    }
}

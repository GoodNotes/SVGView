
import Foundation
public class SVGEllipse: SVGShape {

    public var cx: CGFloat
    public var cy: CGFloat
    public var rx: CGFloat
    public var ry: CGFloat

    public init(cx: CGFloat = 0, cy: CGFloat = 0, rx: CGFloat = 0, ry: CGFloat = 0) {
        self.cx = cx
        self.cy = cy
        self.rx = rx
        self.ry = ry
    }

    override public func frame() -> CGRect {
        CGRect(x: cx - rx, y: cy - ry, width: 2*rx, height: 2*ry)
    }

    override func serialize(_ serializer: Serializer) {
        serializer.add("cx", cx, 0).add("cy", cy, 0).add("rx", rx, 0).add("ry", ry, 0)
        super.serialize(serializer)
    }
}


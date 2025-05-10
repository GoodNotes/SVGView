
import Foundation
public class SVGCircle: SVGShape {

    public var cx: CGFloat
    public var cy: CGFloat
    public var r: CGFloat

    public init(cx: CGFloat = 0, cy: CGFloat = 0, r: CGFloat = 0) {
        self.cx = cx
        self.cy = cy
        self.r = r
    }

    override public func frame() -> CGRect {
        CGRect(x: cx - r, y: cy - r, width: 2*r, height: 2*r)
    }

    override func serialize(_ serializer: Serializer) {
        serializer.add("cx", cx, 0).add("cy", cy, 0).add("r", r, 0)
        super.serialize(serializer)
    }

}

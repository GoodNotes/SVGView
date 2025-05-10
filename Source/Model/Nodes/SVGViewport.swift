
import Foundation
public class SVGViewport: SVGGroup {

    public var width: SVGLength

    public var height: SVGLength

    public var viewBox: CGRect?

    public var preserveAspectRatio: SVGPreserveAspectRatio

    public init(width: SVGLength, height: SVGLength, viewBox: CGRect? = .none, preserveAspectRatio: SVGPreserveAspectRatio, contents: [SVGNode] = []) {
        self.width = width
        self.height = height
        self.viewBox = viewBox
        self.preserveAspectRatio = preserveAspectRatio
        super.init(contents: contents)
    }

    override public func bounds() -> CGRect {
        let size = computeSize(parent: .zero)
        return CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }

    override func serialize(_ serializer: Serializer) {
        serializer.add("width", width.toString(), "100%")
        serializer.add("height", height.toString(), "100%")
        serializer.add("viewBox", viewBox)
        serializer.add("scaling", preserveAspectRatio.scaling)
        serializer.add("xAlign", preserveAspectRatio.xAlign)
        serializer.add("yAlign", preserveAspectRatio.yAlign)
        super.serialize(serializer)
    }
    
    private func computeSize(parent: CGSize) -> CGSize {
        return CGSize(width: width.toPixels(total: parent.width),
                      height: height.toPixels(total: parent.height))
    }

}

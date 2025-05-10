import Foundation


public class SVGGroup: SVGNode {

    public var contents: [SVGNode] = []

    public init(
        contents: [SVGNode],
        transform: CGAffineTransform? = nil,
        opaque: Bool = true,
        opacity: Double = 1,
        clip: SVGUserSpaceNode? = nil,
        mask: SVGNode? = nil
    ) {
        super.init(
            transform: transform ?? .identity,
            opaque: opaque,
            opacity: opacity,
            clip: clip,
            mask: mask
        )
        self.contents = contents
    }

    override public func bounds() -> CGRect {
        contents.map { $0.bounds() }.reduce(contents.first?.bounds() ?? CGRect.zero) { $0.union($1) }
    }

    override public func getNode(byId id: String) -> SVGNode? {
        if let node = super.getNode(byId: id) {
            return node
        }
        for node in contents {
            if let node = node.getNode(byId: id) {
                return node
            }
        }
        return .none
    }

    override func serialize(_ serializer: Serializer) {
        super.serialize(serializer)
        serializer.add("contents", contents)
    }
}

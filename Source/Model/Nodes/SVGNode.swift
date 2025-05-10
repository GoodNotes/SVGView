import Foundation


public class SVGNode: SerializableElement {

    public var transform: CGAffineTransform = CGAffineTransform.identity
    public var opaque: Bool
    public var opacity: Double
    public var clip: SVGNode?
    public var mask: SVGNode?
    public var id: String?

    public init(
        transform: CGAffineTransform? = nil,
        opaque: Bool = true,
        opacity: Double = 1,
        clip: SVGNode? = nil,
        mask: SVGNode? = nil,
        id: String? = nil
    ) {
        self.transform = transform ?? .identity
        self.opaque = opaque
        self.opacity = opacity
        self.clip = clip
        self.mask = mask
        self.id = id
    }

    public func bounds() -> CGRect {
        let frame = frame()
        return CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
    }
    
    public func frame() -> CGRect {
        fatalError()
    }

    public func getNode(byId id: String) -> SVGNode? {
        return self.id == id ? self : .none
    }

    func serialize(_ serializer: Serializer) {
        if !transform.isIdentity {
            serializer.add("transform", transform)
        }
        serializer.add("opacity", opacity, 1)
        serializer.add("opaque", opaque, true)
        serializer.add("clip", clip).add("mask", mask)
    }

    var typeName: String {
        return String(describing: type(of: self))
    }
}

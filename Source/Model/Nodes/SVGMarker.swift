#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
import Combine
#endif

public class SVGMarker: SVGNode {
    public enum Orient {
        public init?(rawValue: String) {
            if rawValue == "auto" {
                self = .auto
            } else if rawValue == "auto-start-reverse" {
                self = .autoStartReverse
            } else if let angle = Float(rawValue) {
                self = .angle(angle)
            } else {
                self = .angle(0)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .auto:
                return "auto"
            case .autoStartReverse:
                return "auto-start-reverse"
            case .angle(let f):
                return "\(f)"
            }
        }
        
        case auto
        case autoStartReverse
        case angle(Float)
    }

    public enum RefMagnitude {
        case left
        case center
        case right
        case coordinate(CGFloat)
    }

    public enum MarkerUnits: String, SerializableEnum {
        case userSpaceOnUse
        case strokeWidth
    }

    #if os(WASI) || os(Linux)
    // TODO
    public var contents: [SVGNode] = []
    #else
    @Published public var markerHeight: SVGLength
    @Published public var markerUnits: MarkerUnits
    @Published public var markerWidth: SVGLength
    @Published public var orient: Orient
    @Published public var preserveAspectRatio: SVGPreserveAspectRatio
    @Published public var refX: RefMagnitude
    @Published public var refY: RefMagnitude
    @Published public var viewBox: CGRect?
    @Published public var contents: [SVGNode] = []
//    @Published public var id: String?
    #endif

    public init(markerHeight: SVGLength, markerUnits: MarkerUnits, markerWidth: SVGLength, orient: Orient, preserveAspectRatio: SVGPreserveAspectRatio, refX: RefMagnitude, refY: RefMagnitude, viewBox: CGRect? = nil, contents: [SVGNode]) {
        self.markerHeight = markerHeight
        self.markerUnits = markerUnits
        self.markerWidth = markerWidth
        self.orient = orient
        self.preserveAspectRatio = preserveAspectRatio
        self.refX = refX
        self.refY = refY
        self.viewBox = viewBox
        self.contents = contents
    }

    override public func bounds() -> CGRect {
        contents.map { $0.bounds() }.reduce(contents.first?.bounds() ?? CGRect.zero) { $0.union($1) }
    }

    override public func getNode(byId id: String) -> SVGMarker? {
        self.id == id ? self : .none
    }

    override func serialize(_ serializer: Serializer) {
        // TODO
        serializer.add("viewBox", viewBox)
//        serializer.add("scaling", preserveAspectRatio.scaling)
//        serializer.add("xAlign", preserveAspectRatio.xAlign)
//        serializer.add("yAlign", preserveAspectRatio.yAlign)
        serializer.add("contents", contents)
        serializer.add("markerHeight", markerHeight.toString(), "100%")
        serializer.add("markerWidth", markerWidth.toString(), "100%")
        serializer.add("markerUnits", markerUnits)
        // TODO
        super.serialize(serializer)

    }

    #if canImport(SwiftUI)
    public func contentView() -> some View {
        SVGMarkerView(model: self)
    }
    #endif

    override var typeName: String {
        return String(describing: type(of: self))
    }

    func parseContents(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> [SVGNode] {
        return context.element.contents
            .compactMap { $0 as? XMLElement }
            .compactMap { delegate($0) }
    }
}

#if canImport(SwiftUI)
extension SVGMarker: ObservableObject {}
struct SVGMarkerView: View {

    @ObservedObject var model: SVGMarker

    public var body: some View {
        ZStack {
            ForEach(0..<model.contents.count, id: \.self) { i in
                if i <= model.contents.count - 1 {
                    model.contents[i].toSwiftUI()
                }
            }
        }
        .compositingGroup() // so that all the following attributes are applied to the group as a whole
        .applyNodeAttributes(model: model)
    }
}
#endif


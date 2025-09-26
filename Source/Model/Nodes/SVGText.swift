#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
import Combine
#endif

public class SVGText: SVGNode {
    public struct Shift: Codable {
        public let dx: String?
        public let dy: String?

        public static let empty = Shift(dx: nil, dy: nil)
    }

    public enum Anchor: String, SerializableEnum {
        case leading
        case center
        case trailing
    }
    
    #if os(WASI) || os(Linux)
    public var text: String
    public var font: SVGFont?
    public var fill: SVGPaint?
    public var stroke: SVGStroke?
    public var textAnchor: Anchor = .leading
    public var textAnchorString: String? = nil
    public var contents: [SVGNode] = [] // Store tspan and text without tspan
    public var shift: Shift? = nil
    #else
    @Published public var text: String
    @Published public var font: SVGFont?
    @Published public var fill: SVGPaint?
    @Published public var stroke: SVGStroke?
    @Published public var textAnchor: Anchor = .leading
    @Published public var textAnchorString: String? = nil
    @Published public var contents: [SVGNode] = []
    @Published public var shift: Shift? = nil
    #endif
    
    public init(
        text: String,
        font: SVGFont? = nil,
        fill: SVGPaint? = SVGColor.black,
        stroke: SVGStroke? = nil,
        textAnchor: Anchor = .leading,
        transform: CGAffineTransform = .identity,
        contents: [SVGNode] = [],
        opaque: Bool = true,
        opacity: Double = 1,
        clip: SVGUserSpaceNode? = nil,
        mask: SVGNode? = nil,
        shift: SVGText.Shift = .empty,
        textAnchorString: String? = nil
    ) {
        self.text = text
        self.font = font
        self.fill = fill
        self.stroke = stroke
        self.textAnchor = textAnchor
        self.contents = contents
        self.shift = shift
        self.textAnchorString = textAnchorString
        super.init(transform: transform, opaque: opaque, opacity: opacity, clip: clip, mask: mask)
    }

    override func serialize(_ serializer: Serializer) {
        serializer.add("text", text).add("font", font).add("textAnchor", textAnchor)
        fill?.serialize(key: "fill", serializer: serializer)
        serializer.add("stroke", stroke)
        super.serialize(serializer)
    }
    
    #if canImport(SwiftUI)
    public func contentView() -> some View {
        SVGTextView(model: self)
    }
    #endif
}

#if canImport(SwiftUI)
extension SVGText: ObservableObject {}

extension SVGText.Anchor {
    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
}
struct SVGTextView: View {

    @ObservedObject var model: SVGText

    public var body: some View {
        if let stroke = model.stroke, let fill = model.fill {
            ZStack {
                // TODO: just a temporary fix, should be replaced with a better solution
                let hw = stroke.width / 2
                filledText(fill: stroke.fill).offset(x: hw, y: hw)
                filledText(fill: stroke.fill).offset(x: -hw, y: -hw)
                filledText(fill: stroke.fill).offset(x: -hw, y: hw)
                filledText(fill: stroke.fill).offset(x: hw, y: -hw)
                filledText(fill: fill)
            }
        } else {
            filledText(fill: model.fill)
        }
    }

    private func filledText(fill: SVGPaint?) -> some View {
        Text(model.text)
           .font(model.font?.toSwiftUI())
           .lineLimit(1)
           .alignmentGuide(.leading) {
               d in d[model.textAnchor.horizontalAlignment]
           }
           .alignmentGuide(VerticalAlignment.top) { d in d[VerticalAlignment.firstTextBaseline] }
           .position(x: 0, y: 0) // just to specify that positioning is global, actual coords are in transform
           .apply(paint: fill)
           .transformEffect(model.transform)
           .frame(alignment: .topLeading)
    }
}
#endif

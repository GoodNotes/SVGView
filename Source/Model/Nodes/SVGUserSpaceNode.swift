//
//  SVGUserSpaceNode.swift
//  Pods
//
//  Created by Alisa Mylnikova on 14/10/2020.
//

#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
#endif

public class SVGUserSpaceNode: SVGNode {

    public enum UserSpace: String, SerializableEnum {

        case objectBoundingBox
        case userSpaceOnUse
    }

    public let node: SVGNode
    public let userSpace: UserSpace

    public init(node: SVGNode, userSpace: UserSpace) {
        self.node = node
        self.userSpace = userSpace
    }
    
    override func serialize(_ serializer: Serializer) {
        serializer.add("userSpace", userSpace)
        super.serialize(serializer)
    }

    #if canImport(SwiftUI)
    public func contentView() -> some View {
        SVGUserSpaceNodeView(model: self)
    }
    #endif
}

#if canImport(SwiftUI)
struct SVGUserSpaceNodeView: View {
    let model: SVGUserSpaceNode

    var body: some View {
        if model.userSpace == .userSpaceOnUse {
            return model.node.toSwiftUI()
        } else {
            fatalError("Pass absolute node parameter for objectBoundingBox to work properly")
        }
    }
}
#endif

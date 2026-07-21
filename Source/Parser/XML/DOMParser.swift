//
//  DOMParser.swift
//  SVGView
//
//  Created by Alisa Mylnikova on 20/08/2020.
//

#if FOUNDATION_ESSENTIALS_BUILD
import FoundationEssentials
import SAXParser
import XMLCore
#else
import Foundation
#if os(WASI) || os(Linux) || os(Android)
import FoundationXML
#endif
#endif

public struct DOMParser {

    static public func parse(contentsOf url: URL, logger: SVGLogger = .console) -> XMLElement? {
        #if FOUNDATION_ESSENTIALS_BUILD
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return parse(bytes: Array(data), logger: logger)
        #else
        return parse(XMLParser(contentsOf: url), logger: logger)
        #endif
    }

    @available(*, deprecated, message: "Use parse(contentsOf:) function instead")
    static public func parse(fileURL: URL, logger: SVGLogger = .console) -> XMLElement? {
        parse(contentsOf: fileURL, logger: logger)
    }

    static public func parse(data: Data, logger: SVGLogger = .console) -> XMLElement? {
        #if FOUNDATION_ESSENTIALS_BUILD
        return parse(bytes: Array(data), logger: logger)
        #else
        return parse(XMLParser(data: data), logger: logger)
        #endif
    }

    static public func parse(string: String?, using encoding: String.Encoding = .utf8, logger: SVGLogger = .console) -> XMLElement? {
        guard let string else {
            return nil
        }

        #if FOUNDATION_ESSENTIALS_BUILD
        return parse(bytes: Array(string.utf8), logger: logger)
        #else
        guard let data = string.data(using: encoding) else {
            return nil
        }
        return parse(XMLParser(data: data), logger: logger)
        #endif
    }

    #if !FOUNDATION_ESSENTIALS_BUILD
    static public func parse(stream: InputStream, logger: SVGLogger = .console) -> XMLElement? {
        parse(XMLParser(stream: stream), logger: logger)
    }
    #endif

    #if FOUNDATION_ESSENTIALS_BUILD
    static private func parse(bytes: [UInt8], logger: SVGLogger) -> XMLElement? {
        var parser = SAXParser(handler: XylemXMLDelegate())

        do {
            try parser.parse(bytes: bytes.span)
            return parser.handler.root
        } catch {
            logger.log(error: error)
            return nil
        }
    }
    #else
    static private func parse(_ parser: XMLParser?, logger: SVGLogger) -> XMLElement? {
        let delegate = FoundationXMLDelegate(logger: logger)
        parser?.delegate = delegate
        parser?.parse()
        return delegate.root
    }
    #endif
}

#if FOUNDATION_ESSENTIALS_BUILD
private struct XylemXMLDelegate: Handler {

    typealias Failure = XML.Error

    var location: XML.Location?

    var root: XMLElement?
    var stack = [XMLElement]()

    mutating func start(
        element name: XML.QualifiedNameView,
        namespace uri: Span<XML.Byte>?,
        attributes: XML.ResolvedAttributes
    ) {
        let element = XMLElement(
            name: decode(name.bytes),
            attributes: decode(attributes: attributes)
        )
        stack.last?.contents.append(element)
        stack.append(element)
        if root == nil {
            root = element
        }
    }

    mutating func end(element name: XML.QualifiedNameView, namespace uri: Span<XML.Byte>?) {
        _ = stack.popLast()
    }

    mutating func characters(_ data: Span<XML.Byte>) {
        guard let element = stack.last else {
            return
        }

        let string = decode(data)
        guard !string.isEmpty else {
            return
        }

        if let textNode = element.contents.last as? XMLText {
            textNode.text.append(string)
        } else {
            element.contents.append(XMLText(text: string))
        }
    }

    mutating func character(data: Span<XML.Byte>) {
        characters(data)
    }

    mutating func comment(_ content: Span<XML.Byte>) {}
    mutating func declaration(version: Span<XML.Byte>, encoding: Span<XML.Byte>?, standalone: Span<XML.Byte>?) {}
    mutating func start(document: Void) {}
    mutating func end(document: Void) {}
    mutating func processing(target: Span<XML.Byte>, data: Span<XML.Byte>?) {}
    mutating func start(mapping prefix: Span<XML.Byte>?, uri: Span<XML.Byte>) {}
    mutating func end(mapping prefix: Span<XML.Byte>?) {}
    mutating func start(dtd name: Span<XML.Byte>, id: (public: Span<XML.Byte>?, system: Span<XML.Byte>?)) {}
    mutating func end(dtd: Void) {}

    private func decode(_ bytes: Span<XML.Byte>) -> String {
        bytes.withUnsafeBufferPointer {
            String(decoding: $0, as: UTF8.self)
        }
    }

    private func decode(attributes: XML.ResolvedAttributes) -> [String: String] {
        var result = [String: String]()
        result.reserveCapacity(attributes.count)

        for index in attributes.indices {
            result[decode(attributes.name(at: index).bytes)] = decode(attributes.value(at: index))
        }

        return result
    }
}
#else
private class FoundationXMLDelegate: NSObject, XMLParserDelegate {

    let logger: SVGLogger
    var root: XMLElement?
    var stack = [XMLElement]()

    init(logger: SVGLogger) {
        self.logger = logger
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let element = XMLElement(name: elementName, attributes: attributeDict)
        stack.last?.contents.append(element)
        stack.append(element)
        if root == nil {
            root = element
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        _ = stack.popLast()
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let element = stack.last {
            if let textNode = element.contents.last as? XMLText {
                textNode.text.append(string)
            } else {
                element.contents.append(XMLText(text: string))
            }
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        logger.log(error: parseError)
    }
}
#endif

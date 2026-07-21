import XCTest
import class SVGView.XMLElement
import class SVGView.XMLText

@testable import SVGView

final class DOMParserTests: XCTestCase {
    func testParsesSVGTree() throws {
        let source = "<svg width='100' height='50'><rect id='shape' width='10' height='20'/></svg>"
        let xml = try XCTUnwrap(DOMParser.parse(string: source))

        let root = try XCTUnwrap(SVGParser.parse(xml: xml))

        XCTAssertNotNil(root.getNode(byId: "shape"))
    }

    func testParsesAttributesAndTextEntities() throws {
        let source = "<svg><text id='label'>one &amp; two</text></svg>"
        let root = try XCTUnwrap(DOMParser.parse(string: source))
        let textElement = try XCTUnwrap(root.contents.first as? XMLElement)
        let text = try XCTUnwrap(textElement.contents.first as? XMLText)

        XCTAssertEqual(textElement.attributes["id"], "label")
        XCTAssertEqual(text.text, "one & two")
    }

    func testPreservesQualifiedAttributeNames() throws {
        let source = "<svg xmlns:xlink='http://www.w3.org/1999/xlink'><use xlink:href='#shape'/></svg>"
        let root = try XCTUnwrap(DOMParser.parse(string: source))
        let use = try XCTUnwrap(root.contents.first as? XMLElement)

        XCTAssertEqual(use.attributes["xlink:href"], "#shape")
    }
}

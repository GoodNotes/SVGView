import Foundation
import XCTest

@testable import SVGView

final class SVGParsingUtilitiesTests: XCTestCase {
    func testStringUtilitiesMatchFoundationWhitespaceBehavior() {
        let values = [
            "",
            "plain",
            "  padded  ",
            "\tline one\nline two\r\n",
            "one   two\tthree",
        ]

        for value in values {
            XCTAssertEqual(
                SVGStringUtilities.trimmed(value),
                value.trimmingCharacters(in: .whitespacesAndNewlines),
                value
            )
            XCTAssertEqual(
                SVGStringUtilities.removingWhitespace(from: value),
                value.components(separatedBy: .whitespacesAndNewlines).joined(),
                value
            )
            XCTAssertEqual(
                SVGStringUtilities.collapsingWhitespace(
                    in: SVGStringUtilities.trimmed(value)
                ),
                foundationCollapsingWhitespace(
                    in: value.trimmingCharacters(in: .whitespacesAndNewlines)
                ),
                value
            )
        }
    }

    func testCollapsingWhitespaceTrimsEdgesAndCollapsesRuns() {
        let values = [
            ("", ""),
            ("   ", ""),
            ("  hello  ", "hello"),
            ("hello   world", "hello world"),
            ("\thello\n\rworld  ", "hello world"),
        ]

        for (value, expected) in values {
            XCTAssertEqual(
                SVGStringUtilities.collapsingWhitespace(in: value),
                expected,
                value
            )
        }
    }

    func testRemovingCharactersMatchingPredicate() {
        XCTAssertEqual(
            SVGStringUtilities.removing(from: "##shape#", where: { $0 == "#" }),
            "shape"
        )
        XCTAssertEqual(
            SVGStringUtilities.removing(from: "100%%", where: { $0 == "%" }),
            "100"
        )
    }

    func testSplitOmitsEmptySubsequences() {
        XCTAssertEqual(
            SVGStringUtilities.split(",10,, 20\t30,") {
                $0 == "," || $0.isWhitespace
            },
            ["10", "20", "30"]
        )
    }

    func testStripURLIdentifierRequiresCompleteWrapper() {
        XCTAssertEqual(
            SVGStringUtilities.stripURLIdentifier("url(#gradient)"),
            "gradient"
        )
        XCTAssertNil(SVGStringUtilities.stripURLIdentifier("#gradient"))
        XCTAssertNil(SVGStringUtilities.stripURLIdentifier("url(#gradient"))
        XCTAssertNil(SVGStringUtilities.stripURLIdentifier("gradient)"))
    }

    func testHexUtilitiesMatchFoundationFormatting() {
        for value in [0, 1, 15, 16, 127, 255, 256, -1] {
            XCTAssertEqual(
                SVGStringUtilities.hexByteString(value),
                String(format: "%02X", value & 0xff),
                "value: \(value)"
            )
        }

        for value in ["0", "0f", "FF", "abcdef"] {
            let scanner = Scanner(string: value)
            var expected: UInt64 = 0
            XCTAssertTrue(scanner.scanHexInt64(&expected), value)
            XCTAssertEqual(SVGStringUtilities.parseHex(value), expected, value)
        }
    }

    func testParseHexRejectsInvalidInput() {
        for value in ["", "xyz", "FFgarbage", " FF"] {
            XCTAssertNil(SVGStringUtilities.parseHex(value), value)
        }
    }

    func testNumberAndUnitParserMatchesFoundationScanner() {
        let values = [
            "0",
            "12",
            "-3.5px",
            "+.5%",
            "1e3",
            "-2.5e-2em",
            " 42 px ",
            "5.",
            "1e",
            "invalid",
        ]

        for value in values {
            let expected = foundationNumberAndUnit(from: value)
            let actual = SVGNumberParser.numberAndUnit(from: value)

            XCTAssertEqual(actual?.value, expected?.value, value)
            XCTAssertEqual(actual?.unit, expected?.unit, value)
        }
    }

    func testNumberListParserMatchesFoundationScanner() {
        let values = [
            "0 1",
            "0,1 2,3",
            "-1.5e2,+.25 5. 6e-2",
            " 10, 20, 30, 40 ",
        ]

        for value in values {
            XCTAssertEqual(
                SVGNumberParser.numbers(in: value),
                foundationNumbers(in: value),
                value
            )
        }
    }

    func testTransformParserAcceptsLeadingPlus() {
        let operations = SVGTransformParser.operations(in: "translate(0, +40)")

        XCTAssertEqual(operations.count, 1)
        XCTAssertEqual(operations[0].name, "translate")
        XCTAssertEqual(operations[0].values, [0, 40])
    }

    func testTransformParserParsesSupportedSVGNumberSyntax() {
        let cases: [(value: String, expected: [(name: String, values: [Double])])] = [
            ("translate(10, 20)", [("translate", [10, 20])]),
            ("scale(2) rotate(-45)", [("scale", [2]), ("rotate", [-45])]),
            (
                "matrix(1 0 0 1 10 -20)",
                [("matrix", [1, 0, 0, 1, 10, -20])]
            ),
            (
                "translate(1e2, -2.5e-1)\nscale(0.5)",
                [("translate", [100, -0.25]), ("scale", [0.5])]
            ),
            (
                "skewX(12.5) skewY(-8)",
                [("skewX", [12.5]), ("skewY", [-8])]
            ),
        ]

        for testCase in cases {
            let actual = SVGTransformParser.operations(in: testCase.value)

            XCTAssertEqual(actual.count, testCase.expected.count, testCase.value)
            for (actualOperation, expectedOperation) in zip(
                actual,
                testCase.expected
            ) {
                XCTAssertEqual(
                    actualOperation.name,
                    expectedOperation.name,
                    testCase.value
                )
                XCTAssertEqual(
                    actualOperation.values,
                    expectedOperation.values,
                    testCase.value
                )
            }
        }
    }

    private func foundationCollapsingWhitespace(in value: String) -> String {
        let regex = try! NSRegularExpression(pattern: "\\s+")
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return regex.stringByReplacingMatches(in: value, range: range, withTemplate: " ")
    }

    private func foundationNumberAndUnit(from value: String) -> (value: Double, unit: String?)? {
        let scanner = Scanner(string: value)
        guard let number = scanner.scanDouble() else {
            return nil
        }

        let unitCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "%"))
        return (number, scanner.scanCharacters(from: unitCharacters))
    }

    private func foundationNumbers(in value: String) -> [Double] {
        let scanner = Scanner(string: value)
        var result = [Double]()

        while !scanner.isAtEnd {
            if let number = scanner.scanDouble() {
                result.append(number)
            }
            _ = scanner.scanCharacters(from: CharacterSet(charactersIn: ","))
        }

        return result
    }

}

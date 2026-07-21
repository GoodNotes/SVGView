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

    func testTransformParserMatchesFoundationRegex() throws {
        let values = [
            "translate(10, 20)",
            "scale(2) rotate(-45)",
            "matrix(1 0 0 1 10 -20)",
            "translate(1e2, -2.5e-1)\nscale(0.5)",
            "skewX(12.5) skewY(-8)",
        ]

        for value in values {
            let expected = try foundationTransformOperations(in: value)
            let actual = SVGTransformParser.operations(in: value)

            XCTAssertEqual(actual.count, expected.count, value)
            for (actualOperation, expectedOperation) in zip(actual, expected) {
                XCTAssertEqual(actualOperation.name, expectedOperation.name, value)
                XCTAssertEqual(actualOperation.values, expectedOperation.values, value)
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

    private func foundationTransformOperations(
        in value: String
    ) throws -> [(name: String, values: [Double])] {
        let attributeRegex = try NSRegularExpression(
            pattern: "([a-z]+)\\(((\\-?\\d+\\.?\\d*e?\\-?\\d*\\s*,?\\s*)+)\\)",
            options: .caseInsensitive
        )
        let numberRegex = try NSRegularExpression(
            pattern: "\\-?\\d+\\.?\\d*e?\\-?\\d*",
            options: .caseInsensitive
        )

        var remaining = value.replacingOccurrences(of: "\n", with: "")
        var result = [(name: String, values: [Double])]()

        while let match = attributeRegex.firstMatch(
            in: remaining,
            range: NSRange(remaining.startIndex..<remaining.endIndex, in: remaining)
        ) {
            let name = (remaining as NSString).substring(with: match.range(at: 1))
            let valuesString = (remaining as NSString).substring(with: match.range(at: 2))
            let values = numberRegex.matches(
                in: valuesString,
                range: NSRange(valuesString.startIndex..<valuesString.endIndex, in: valuesString)
            ).compactMap { match in
                Double((valuesString as NSString).substring(with: match.range))
            }
            result.append((name, values))

            let consumedLength = match.range.location + match.range.length
            remaining = (remaining as NSString).substring(from: consumedLength)
        }

        return result
    }
}

enum SVGStringUtilities {

    static func trimmed(_ string: String) -> String {
        guard
            let start = string.firstIndex(where: { !$0.isWhitespace }),
            let end = string.lastIndex(where: { !$0.isWhitespace })
        else {
            return ""
        }

        return String(string[start...end])
    }

    static func removingWhitespace(from string: String) -> String {
        String(string.filter { !$0.isWhitespace })
    }

    static func removing(
        from string: String,
        where shouldRemove: (Character) -> Bool
    ) -> String {
        String(string.filter { !shouldRemove($0) })
    }

    static func collapsingWhitespace(in string: String) -> String {
        var result = String()
        result.reserveCapacity(string.count)

        var shouldInsertSpace = false
        for character in string {
            if character.isWhitespace {
                shouldInsertSpace = !result.isEmpty
                continue
            }

            if shouldInsertSpace {
                result.append(" ")
                shouldInsertSpace = false
            }

            result.append(character)
        }

        return result
    }

    static func split(
        _ string: String,
        where isSeparator: (Character) -> Bool
    ) -> [String] {
        string.split(omittingEmptySubsequences: true, whereSeparator: isSeparator)
            .map(String.init)
    }

    static func parseHex(_ string: String) -> UInt64? {
        UInt64(string, radix: 16)
    }

    static func stripURLIdentifier(_ string: String) -> String? {
        guard string.hasPrefix("url(#"), string.hasSuffix(")") else {
            return nil
        }
        return String(string.dropFirst(5).dropLast())
    }

    static func hexByteString(_ value: Int) -> String {
        let normalized = String(value & 0xff, radix: 16, uppercase: true)
        return normalized.count == 1 ? "0\(normalized)" : normalized
    }
}

enum SVGNumberParser {

    static func numberAndUnit(from string: String) -> (value: Double, unit: String?)? {
        let trimmed = SVGStringUtilities.trimmed(string)
        guard let parsed = parseLeadingNumber(in: trimmed[...]) else {
            return nil
        }

        let unit = SVGStringUtilities.trimmed(String(trimmed[parsed.endIndex...]))
        return (parsed.value, unit.isEmpty ? nil : unit)
    }

    static func numbers(in string: String) -> [Double] {
        var numbers = [Double]()
        var index = string.startIndex

        while index < string.endIndex {
            let character = string[index]
            if character.isWhitespace || character == "," {
                index = string.index(after: index)
                continue
            }

            if let parsed = parseLeadingNumber(in: string[index...]) {
                numbers.append(parsed.value)
                index = parsed.endIndex
            } else {
                index = string.index(after: index)
            }
        }

        return numbers
    }

    private static func parseLeadingNumber(
        in string: Substring
    ) -> (value: Double, endIndex: String.Index)? {
        guard !string.isEmpty else {
            return nil
        }

        let endIndex = string.endIndex
        var index = string.startIndex

        if index < endIndex, string[index] == "+" || string[index] == "-" {
            index = string.index(after: index)
        }

        let integerStart = index
        while index < endIndex, string[index].isWholeNumber {
            index = string.index(after: index)
        }
        let hasIntegerDigits = index != integerStart

        if index < endIndex, string[index] == "." {
            index = string.index(after: index)

            let fractionStart = index
            while index < endIndex, string[index].isWholeNumber {
                index = string.index(after: index)
            }

            if !hasIntegerDigits, index == fractionStart {
                return nil
            }
        } else if !hasIntegerDigits {
            return nil
        }

        let exponentStart = index
        if index < endIndex, string[index] == "e" || string[index] == "E" {
            index = string.index(after: index)

            if index < endIndex, string[index] == "+" || string[index] == "-" {
                index = string.index(after: index)
            }

            let exponentDigitsStart = index
            while index < endIndex, string[index].isWholeNumber {
                index = string.index(after: index)
            }

            if exponentDigitsStart == index {
                index = exponentStart
            }
        }

        let numberString = String(string[..<index])
        guard let value = Double(numberString) else {
            return nil
        }

        return (value, index)
    }
}

enum SVGTransformParser {

    struct Operation {
        let name: String
        let values: [Double]
    }

    static func operations(in string: String) -> [Operation] {
        let cleaned = String(string.filter { $0 != "\n" && $0 != "\r" })
        var operations = [Operation]()
        var index = cleaned.startIndex

        while index < cleaned.endIndex {
            while index < cleaned.endIndex, cleaned[index].isWhitespace {
                index = cleaned.index(after: index)
            }

            let nameStart = index
            while index < cleaned.endIndex, isASCIIAlpha(cleaned[index]) {
                index = cleaned.index(after: index)
            }

            guard nameStart != index else {
                index = cleaned.index(after: index)
                continue
            }

            while index < cleaned.endIndex, cleaned[index].isWhitespace {
                index = cleaned.index(after: index)
            }

            guard index < cleaned.endIndex, cleaned[index] == "(" else {
                continue
            }

            let name = String(cleaned[nameStart..<index])
            index = cleaned.index(after: index)

            let valuesStart = index
            while index < cleaned.endIndex, cleaned[index] != ")" {
                index = cleaned.index(after: index)
            }

            let values = SVGNumberParser.numbers(in: String(cleaned[valuesStart..<index]))
            operations.append(Operation(name: name, values: values))

            if index < cleaned.endIndex {
                index = cleaned.index(after: index)
            }
        }

        return operations
    }

    private static func isASCIIAlpha(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first, character.unicodeScalars.count == 1 else {
            return false
        }
        return (65...90).contains(scalar.value) || (97...122).contains(scalar.value)
    }
}

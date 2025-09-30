// MARK: - Code Formatter

import Foundation

public struct CodeFormatter: InputFormatter {
  public let length: Int

  public init(length: Int = 4) {
    self.length = length
  }

  public func format(change: TextChange) -> FormattingResult {
    var digits = change.previousText.filter(\.isNumber)
    let newDigits = change.replacementString.filter(\.isNumber)

    let digitsInPrefix = change.previousText[..<change.changeRange.lowerBound]
      .filter(\.isNumber).count
    let digitsInChange = change.previousText[change.changeRange]
      .filter(\.isNumber).count

    if let r = Range(
      NSRange(location: digitsInPrefix, length: digitsInChange), in: digits) {
      digits.replaceSubrange(r, with: newDigits)
    }

    if digits.count > length {
      digits = String(digits.prefix(length))
    }

    let cursorIndex = min(digitsInPrefix + newDigits.count, digits.count)
    return FormattingResult(formattedText: String(digits), cursorPosition: cursorIndex)
  }

  public func shouldAllowCharacter(_ character: Character, at position: Int, in text: String)
    -> Bool
  {
    character.isNumber
  }

  public func filterRawText(_ text: String) -> String {
    String(text.filter(\.isNumber))
  }

  public var maxRawLength: Int? { length }
  public var maxFormattedLength: Int? { length }

  public func isValidFormat(_ formattedText: String) -> Bool {
    let digits = formattedText.filter(\.isNumber)
    return digits.count == length
  }
}


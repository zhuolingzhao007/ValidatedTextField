//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//
import UIKit

// MARK: - Built-in Formatter Examples

public struct PhoneFormatter: InputFormatter {
  
  public init() {}
  
  public func format(change: TextChange) -> FormattingResult {
    var digits = change.previousText.filter(\.isNumber)
    let newDigits = change.replacementString.filter(\.isNumber)

    let digitsInPrefix = change.previousText[..<change.changeRange.lowerBound]
      .filter(\.isNumber).count
    let digitsInChange = change.previousText[change.changeRange]
      .filter(\.isNumber).count

    let digitRange = NSRange(location: digitsInPrefix, length: digitsInChange)

    if let r = Range(digitRange, in: digits) {
      digits.replaceSubrange(r, with: newDigits)
    }

    if digits.count > 11 {
      digits = String(digits.prefix(11))
    }

    let finalCursorIndex = digitsInPrefix + newDigits.count
    return formatResult(Array(digits), cursorDigitIndex: finalCursorIndex)
  }
  
  private func formatResult(_ digits: [Character], cursorDigitIndex: Int) -> FormattingResult {
    // Reformat all remaining digits
    var formatted = ""
    for (i, digit) in digits.enumerated() {
      if i == 3 || i == 7 { formatted += " " }
      formatted.append(digit)
    }

    // Cursor position: before the cursorDigitIndex-th digit
    var cursorPos = cursorDigitIndex
    if cursorDigitIndex > 3 { cursorPos += 1 }
    if cursorDigitIndex > 7 { cursorPos += 1 }

    return FormattingResult(formattedText: formatted, cursorPosition: min(cursorPos, formatted.count))
  }

  // MARK: - InputFormatter Protocol
  public func shouldAllowCharacter(_ character: Character, at position: Int, in text: String) -> Bool {
    character.isNumber
  }
  
  public func filterRawText(_ text: String) -> String {
    String(text.filter(\.isNumber))
  }
  
  public var maxRawLength: Int? { 11 }
  public var maxFormattedLength: Int? { 13 }
  
  public func isValidFormat(_ formattedText: String) -> Bool {
    let digits = formattedText.filter(\.isNumber)
    // Regex for mainland China mobile numbers
    let regex = "^1[3-9]\\d{9}$"
    let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
    return predicate.evaluate(with: digits)
  }
}

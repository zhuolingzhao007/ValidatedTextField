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
    // 1. Get the raw digits from the old text
    var digits = change.previousText.filter(\.isNumber)

    // 2. Calculate the range of digits to be replaced
    let digitsInPrefix = change.previousText.prefix(change.changeRange.location).filter(\.isNumber).count
    let digitsInChangeRange = change.previousText[change.changeRange].filter(\.isNumber).count
    let digitRange = NSRange(location: digitsInPrefix, length: digitsInChangeRange)

    // 3. Get the new digits to insert
    let newDigits = change.replacementString.filter(\.isNumber)

    // 4. Handle the case where a space is deleted (as per user's request)
    if digitsInChangeRange == 0 && change.isDeletion && change.changeRange.length > 0 {
        // Deleting spaces or other non-digits.
        // If the user deletes a space, we delete the preceding digit.
        if digitRange.location > 0 {
            let rangeToDelete = NSRange(location: digitRange.location - 1, length: 1)
            if let r = Range(rangeToDelete, in: digits) {
                digits.removeSubrange(r)
                // The cursor should be placed where the deleted digit was.
                return formatResult(Array(digits), cursorDigitIndex: rangeToDelete.location)
            }
        }
    }

    // 5. Replace the range of old digits with the new digits
    if let r = Range(digitRange, in: digits) {
        digits.replaceSubrange(r, with: newDigits)
    }

    // 6. Truncate to max length (11 digits for phone number)
    if digits.count > 11 {
        digits = String(digits.prefix(11))
    }

    // 7. Format the final digits and calculate the new cursor position
    let finalCursorIndex = digitRange.location + newDigits.count
    return formatResult(Array(digits), cursorDigitIndex: finalCursorIndex)
  }
  
  private func formatResult(_ digits: [Character], cursorDigitIndex: Int) -> FormattingResult {
    // 重新格式化所有剩余数字
    var formatted = ""
    for (i, digit) in digits.enumerated() {
      if i == 3 || i == 7 { formatted += " " }
      formatted.append(digit)
    }
    
    // 光标位置：第cursorDigitIndex个数字前
    var cursorPos = cursorDigitIndex
    if cursorDigitIndex > 3 { cursorPos += 1 }
    if cursorDigitIndex > 7 { cursorPos += 1 }
    
    return FormattingResult(formattedText: formatted, cursorPosition: min(cursorPos, formatted.count))
  }
  
  // MARK: - InputFormatter 协议
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
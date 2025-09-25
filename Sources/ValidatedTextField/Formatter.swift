//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//


// MARK: - Formatting Result
public struct FormattingResult {
  public let formattedText: String
  public let cursorPosition: Int?  // New cursor position, nil means no change
  
  public init(formattedText: String, cursorPosition: Int? = nil) {
    self.formattedText = formattedText
    self.cursorPosition = cursorPosition
  }
}

// MARK: - Text Change Information
public struct TextChange {
  public let previousText: String      // Text before change
  public let newText: String          // Text after change
  public let changeRange: NSRange     // Change range
  public let replacementString: String // Replacement string
  public let cursorPosition: Int      // Current cursor position
  
  public init(
    previousText: String,
    newText: String,
    changeRange: NSRange,
    replacementString: String,
    cursorPosition: Int
  ) {
    self.previousText = previousText
    self.newText = newText
    self.changeRange = changeRange
    self.replacementString = replacementString
    self.cursorPosition = cursorPosition
  }
  
  // Convenience properties
  public var isInsertion: Bool { !replacementString.isEmpty }
  public var isDeletion: Bool { replacementString.isEmpty && changeRange.length > 0 }
  public var isReplacement: Bool { !replacementString.isEmpty && changeRange.length > 0 }
}

// MARK: - Formatting Protocol
public protocol InputFormatter {

  /// Unified formatting method - handle text changes
  func format(change: TextChange) -> FormattingResult

  // MARK: - Character Filtering
  /// Whether to allow input of specified character
  func shouldAllowCharacter(_ character: Character, at position: Int, in text: String) -> Bool

  /// Filter raw text, keep only allowed characters
  func filterRawText(_ text: String) -> String

  // MARK: - Length Limits
  /// Maximum raw character length (after filtering)
  var maxRawLength: Int? { get }

  /// Maximum formatted character length
  var maxFormattedLength: Int? { get }

  // MARK: - Format Validation
  /// Check if formatted text is valid
  func isValidFormat(_ formattedText: String) -> Bool
}

// MARK: - Default Implementation
extension InputFormatter {

  // MARK: - Default Implementation

  public func shouldAllowCharacter(_ character: Character, at position: Int, in text: String) -> Bool {
    return true // Default allows all characters
  }

  public func filterRawText(_ text: String) -> String {
    return text // Default no filtering
  }

  public var maxRawLength: Int? { return nil }
  public var maxFormattedLength: Int? { return nil }

  public func isValidFormat(_ formattedText: String) -> Bool {
    return true // Default considers all valid
  }
}

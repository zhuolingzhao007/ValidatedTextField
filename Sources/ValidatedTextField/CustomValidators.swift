// Custom Validators Extension
// Created for parameterized non-empty validation and copied validators

import Foundation

extension Validator {
  /// Parameterized custom non-empty validation: supports custom messages and trim character sets
  /// - Parameters:
  ///   - message: Error message when invalid
  ///   - trimSet: Character set to trim (default whitespace and newlines)
  /// - Returns: Validator instance
  public static func customNonEmpty(
    message: String, trimSet: CharacterSet = .whitespacesAndNewlines
  ) -> Validator {
    Validator { input in
      let trimmed = input.trimmingCharacters(in: trimSet)
      return trimmed.isEmpty ? .invalid(message: message) : .valid
    }
  }

  // Copied from Validators.swift static let, for quick use
  public static let nonEmpty = Validator { input in
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? .invalid(message: "Cannot be empty") : .valid
  }

  public static let phone = Validator { input in
    let digits = input.filter(\.isNumber)
    if digits.isEmpty {
      return .invalid(message: "Please enter phone number")
    }
    // Validate Chinese mainland mobile phone number using regex
    let regex = "^1[3-9]\\d{9}$"
    let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
    return predicate.evaluate(with: digits) ? .valid : .invalid(message: "Please enter a valid phone number")
  }

  /// Verification code validator: non-empty + length check, supports parameterization
  /// - Parameters:
  ///   - length: Verification code length (default 4)
  ///   - emptyMessage: Empty prompt (default "Verification code cannot be empty")
  /// - Returns: Combined Validator
  public static func codeValidator(length: Int = 4, emptyMessage: String = "Verification code cannot be empty") -> Validator {
    let lengthValidator = Validator { input in
      let digits = input.filter(\.isNumber)
      return digits.count == length ? .valid : .invalid(message: "Verification code must be \(length) digits")
    }
    return customNonEmpty(message: emptyMessage) && lengthValidator
  }
}

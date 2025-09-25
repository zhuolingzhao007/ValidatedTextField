//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//

import UIKit

// MARK: - Validator

// MARK: - ValidationResult

public enum ValidationResult: Equatable {
  case valid
  case invalid(message: String)

  public var isValid: Bool {
    switch self {
    case .valid: return true
    case .invalid: return false
    }
  }

  public var errorMessage: String? {
    switch self {
    case .valid: return nil
    case .invalid(let message): return message
    }
  }
}

public protocol InputValidator {
  func validate(_ raw: String) -> ValidationResult
}

// 组合型 Validator（支持 && || ! 和 Builder）
public struct Validator: InputValidator {
  private let impl: (String) -> ValidationResult

  public init(_ impl: @escaping (String) -> ValidationResult) {
    self.impl = impl
  }

  public func validate(_ raw: String) -> ValidationResult {
    impl(raw)
  }

  public func callAsFunction(_ t: String) -> ValidationResult {
    impl(t)
  }
  
  public static let alwaysTrue = Validator { _ in .valid }
}

public func && (l: Validator, r: Validator) -> Validator {
  .init { input in
    let leftResult = l.validate(input)
    guard leftResult.isValid else { return leftResult }
    return r.validate(input)
  }
}

public func || (l: Validator, r: Validator) -> Validator {
  .init { input in
    let leftResult = l.validate(input)
    if leftResult.isValid { return leftResult }
    return r.validate(input)
  }
}

public prefix func ! (v: Validator) -> Validator {
  .init { input in
    let result = v.validate(input)
    switch result {
    case .valid: return .invalid(message: "验证应该失败")
    case .invalid: return .valid
    }
  }
}

@resultBuilder
public enum ValidatorBuilder {
  public static func buildBlock(_ comps: Validator...) -> Validator {
    comps.reduce(.alwaysTrue, &&)
  }
  public static func buildOptional(_ comp: Validator?) -> Validator {
    comp ?? .alwaysTrue
  }
  public static func buildEither(first: Validator) -> Validator { first }
  public static func buildEither(second: Validator) -> Validator { second }
}

public func createValidator(@ValidatorBuilder _ builder: () -> Validator) -> Validator {
  return builder()
}

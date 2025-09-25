//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//

import UIKit

// MARK: - Strategy

public struct ValidationStrategy {
  public var formatter: InputFormatter?
  public var validator: Validator?
  public var trigger: ValidationTrigger = .onChange

  public init(
    formatter: InputFormatter? = nil,
    validator: Validator? = nil,
    trigger: ValidationTrigger = .onChange
  ) {
    self.formatter = formatter
    self.validator = validator
    self.trigger = trigger
  }

  public init(
    formatter: InputFormatter? = nil,
    @ValidatorBuilder validator: () -> Validator,
    trigger: ValidationTrigger = .onChange
  ) {
    self.formatter = formatter
    self.validator = validator()
    self.trigger = trigger
  }
}

//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//
import UIKit

// MARK: - States

public enum InteractionState: Hashable {
  case idle, editing, disabled
}

public enum ValidationPhase: Hashable {
  case none, valid, invalid
}

public enum ValidationState: Equatable {
  case none
  case valid
  case invalid(message: String?)
  public var phase: ValidationPhase {
    switch self {
    case .none: return .none
    case .valid: return .valid
    case .invalid: return .invalid
    }
  }

  public var isValid: Bool {
    switch self {
    case .none: return false
    case .valid: return true
    case .invalid: return false
    }
  }
}

// MARK: - Trigger

public enum ValidationTrigger {
  case onChange
  case onCommit
  case afterCommitThenChange
}

//
//  NestedBuilder.swift
//  ValidatedTextField
//
//  Created by zhuolingzhao on 10/1/25.
//

import Foundation

// MARK: - NestedBuilder for nested object configuration

@dynamicMemberLookup
public final class NestedBuilder<Target> {
  private var modifications: [(Target) -> Void] = []

  public init() {}

  // Dynamic member lookup for reference types (classes)
  public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<Target, Value>) -> ((Value) -> NestedBuilder) where Target: AnyObject {
    { value in
      self.modifications.append { target in
        target[keyPath: keyPath] = value
      }
      return self
    }
  }

  // Dynamic member lookup for value types (structs)
  public subscript<Value>(dynamicMember keyPath: WritableKeyPath<Target, Value>) -> ((Value) -> NestedBuilder) {
    { value in
      self.modifications.append { target in
        var mutableTarget = target
        mutableTarget[keyPath: keyPath] = value
      }
      return self
    }
  }

  // Apply all modifications to the target
  internal func apply(to target: Target) {
    modifications.forEach { $0(target) }
  }

  // Get all modifications as a single closure
  internal func buildModification() -> (Target) -> Void {
    { target in
      self.modifications.forEach { $0(target) }
    }
  }
}

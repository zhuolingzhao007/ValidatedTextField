//
//  GenericPatch.swift
//  ValidatedTextField
//
//  Created by zhuolingzhao on 10/1/25.
//

import Foundation

// MARK: - Generic Patch for Standard UIKit Controls

/// Generic patch for standard UIKit controls (UIButton, UILabel, UIView, etc.)
/// For custom composite controls, create a custom patch instead
public struct GenericPatch<T>: StylePatchProtocol {
  public typealias Target = T

  // Modifications to apply
  private var modifications: [(T) -> Void] = []

  public init() {}

  // Add a modification
  public mutating func addModification(_ modification: @escaping (T) -> Void) {
    modifications.append(modification)
  }

  // Apply to target
  public func apply(to target: T) {
    modifications.forEach { $0(target) }
  }

  // Merge two patches
  public func merged(with other: GenericPatch<T>) -> GenericPatch<T> {
    var result = GenericPatch<T>()
    // Merge modifications (self first, then other)
    result.modifications = self.modifications + other.modifications
    return result
  }
}

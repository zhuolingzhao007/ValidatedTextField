//
//  TextFieldPatch.swift
//  ValidatedTextField
//
//  Created by zhuolingzhao on 10/1/25.
//

import Foundation

// MARK: - TextField Specific Patch (Custom Composite Control)

/// Custom patch for ValidatedTextField (composite control with layout properties)
public struct TextFieldPatch: StylePatchProtocol {
  public typealias Target = ValidatedTextField

  // Layout properties (specific to ValidatedTextField)
  public var containerPadding: CGFloat?
  public var horizontalPadding: CGFloat?
  public var accessorySpacing: CGFloat?
  public var verticalSpacing: CGFloat?

  // Modifications to apply
  private var modifications: [(ValidatedTextField) -> Void] = []

  public init() {}

  // Add a modification
  public mutating func addModification(_ modification: @escaping (ValidatedTextField) -> Void) {
    modifications.append(modification)
  }

  // Apply to ValidatedTextField
  public func apply(to view: ValidatedTextField) {
    modifications.forEach { $0(view) }
  }

  // Merge two patches
  public func merged(with other: TextFieldPatch) -> TextFieldPatch {
    var result = TextFieldPatch()

    // Merge layout properties
    result.containerPadding = other.containerPadding ?? self.containerPadding
    result.horizontalPadding = other.horizontalPadding ?? self.horizontalPadding
    result.accessorySpacing = other.accessorySpacing ?? self.accessorySpacing
    result.verticalSpacing = other.verticalSpacing ?? self.verticalSpacing

    // Merge modifications (self first, then other)
    result.modifications = self.modifications + other.modifications

    return result
  }
}

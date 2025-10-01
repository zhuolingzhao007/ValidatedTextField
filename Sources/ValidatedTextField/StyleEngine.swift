//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//
import UIKit

// MARK: - Style Infrastructure

public protocol StylePatchProtocol {
  associatedtype Target
  init()
  mutating func addModification(_ modification: @escaping (Target) -> Void)
  func merged(with other: Self) -> Self
}

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

public struct ComponentStyle<Patch: StylePatchProtocol, PrimaryState: Hashable, SecondaryState: Hashable> {
  public var base: Patch
  public var primaryVariants: [PrimaryState: Patch]
  public var secondaryVariants: [SecondaryState: Patch]

  public init(
    base: Patch = .init(),
    primaryVariants: [PrimaryState: Patch] = [:],
    secondaryVariants: [SecondaryState: Patch] = [:]
  ) {
    self.base = base
    self.primaryVariants = primaryVariants
    self.secondaryVariants = secondaryVariants
  }

  // Resolve style for given states
  public func resolve(for primaryState: PrimaryState, _ secondaryState: SecondaryState) -> Patch {
    var resolved = base

    if let primaryPatch = primaryVariants[primaryState] {
      resolved = resolved.merged(with: primaryPatch)
    }

    if let secondaryPatch = secondaryVariants[secondaryState] {
      resolved = resolved.merged(with: secondaryPatch)
    }

    return resolved
  }
}

// MARK: - Generic ComponentStyleBuilder

@dynamicMemberLookup
public final class ComponentStyleBuilder<Patch: StylePatchProtocol, PrimaryState: Hashable, SecondaryState: Hashable> {
  private var base = Patch()
  private var primary: [PrimaryState: Patch] = [:]
  private var secondary: [SecondaryState: Patch] = [:]

  public init() {}

  // Dynamic member lookup for GenericPatch<Target>
  public subscript<Target, Value>(dynamicMember keyPath: WritableKeyPath<Target, Value>) -> ((Value) -> ComponentStyleBuilder) where Patch == GenericPatch<Target> {
    { value in
      var patch = self.base
      patch.addModification { target in
        var mutableTarget = target
        mutableTarget[keyPath: keyPath] = value
      }
      self.base = patch
      return self
    }
  }

  // For reference types when using GenericPatch
  public subscript<Target, Value>(dynamicMember keyPath: ReferenceWritableKeyPath<Target, Value>) -> ((Value) -> ComponentStyleBuilder) where Patch == GenericPatch<Target>, Target: AnyObject {
    { value in
      var patch = self.base
      patch.addModification { target in
        target[keyPath: keyPath] = value
      }
      self.base = patch
      return self
    }
  }

  // Dynamic member lookup for TextFieldPatch (ValidatedTextField)
  public subscript<Value>(dynamicMember keyPath: WritableKeyPath<ValidatedTextField, Value>) -> ((Value) -> ComponentStyleBuilder) where Patch == TextFieldPatch {
    { value in
      var patch = self.base
      patch.addModification { view in
        var mutableView = view
        mutableView[keyPath: keyPath] = value
      }
      self.base = patch
      return self
    }
  }

  // For reference types (ValidatedTextField is a class) when using TextFieldPatch
  public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<ValidatedTextField, Value>) -> ((Value) -> ComponentStyleBuilder) where Patch == TextFieldPatch {
    { value in
      var patch = self.base
      patch.addModification { view in
        view[keyPath: keyPath] = value
      }
      self.base = patch
      return self
    }
  }

  // Custom method - unified for all patch types
  @discardableResult
  public func custom(_ block: @escaping (Patch.Target) -> Void) -> ComponentStyleBuilder {
    var patch = self.base
    patch.addModification(block)
    self.base = patch
    return self
  }

  // Layout configuration helper for TextFieldPatch only
  @discardableResult
  public func layout(_ block: (inout TextFieldPatch) -> Void) -> ComponentStyleBuilder where Patch == TextFieldPatch {
    var patch = self.base
    block(&patch)
    self.base = patch
    return self
  }

  @discardableResult
  public func onPrimaryState(_ state: PrimaryState, _ edit: (ComponentStyleBuilder) -> Void) -> ComponentStyleBuilder {
    let builder = ComponentStyleBuilder<Patch, PrimaryState, SecondaryState>()
    edit(builder)
    primary[state] = builder.base
    return self
  }

  @discardableResult
  public func onSecondaryState(_ state: SecondaryState, _ edit: (ComponentStyleBuilder) -> Void) -> ComponentStyleBuilder {
    let builder = ComponentStyleBuilder<Patch, PrimaryState, SecondaryState>()
    edit(builder)
    secondary[state] = builder.base
    return self
  }

  public func build() -> ComponentStyle<Patch, PrimaryState, SecondaryState> {
    ComponentStyle(base: base, primaryVariants: primary, secondaryVariants: secondary)
  }
}

// MARK: - TextField Specialisations

public typealias TextFieldStyle = ComponentStyle<TextFieldPatch, InteractionState, ValidationPhase>
public typealias TextFieldStyleBuilder = ComponentStyleBuilder<TextFieldPatch, InteractionState, ValidationPhase>
public typealias StyleBuilder = TextFieldStyleBuilder

public extension ComponentStyleBuilder where PrimaryState == InteractionState {
  @discardableResult
  func onInteraction(_ state: InteractionState, _ edit: (ComponentStyleBuilder) -> Void) -> ComponentStyleBuilder {
    onPrimaryState(state, edit)
  }
}

public extension ComponentStyleBuilder where SecondaryState == ValidationPhase {
  @discardableResult
  func onValidation(_ state: ValidationPhase, _ edit: (ComponentStyleBuilder) -> Void) -> ComponentStyleBuilder {
    onSecondaryState(state, edit)
  }
}

// MARK: - Generic UIKit Control Type Aliases

/// Enum placeholder for stateless builders
public enum NoState: Hashable {
  case none
}

/// For styling UIButton (stateless for simplicity, can add state support later)
public typealias ButtonStyleBuilder = ComponentStyleBuilder<GenericPatch<UIButton>, NoState, NoState>

/// For styling UILabel (stateless)
public typealias LabelStyleBuilder = ComponentStyleBuilder<GenericPatch<UILabel>, NoState, NoState>

/// For styling UIView (stateless)
public typealias ViewStyleBuilder = ComponentStyleBuilder<GenericPatch<UIView>, NoState, NoState>

/// For styling UIImageView (stateless)
public typealias ImageViewStyleBuilder = ComponentStyleBuilder<GenericPatch<UIImageView>, NoState, NoState>

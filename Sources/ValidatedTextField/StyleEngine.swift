//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//
import UIKit

// MARK: - Style Infrastructure

public protocol StylePatchProtocol {
  init()
  func merged(with other: Self) -> Self
}

// MARK: - Generic Patch for Standard UIKit Controls

/// Generic patch for standard UIKit controls (UIButton, UILabel, UIView, etc.)
/// For custom composite controls, create a custom patch instead
public struct GenericPatch<Target>: StylePatchProtocol {
  // Modifications to apply
  private var modifications: [(Target) -> Void] = []

  public init() {}

  // Add a modification
  public mutating func addModification(_ modification: @escaping (Target) -> Void) {
    modifications.append(modification)
  }

  // Apply to target
  public func apply(to target: Target) {
    modifications.forEach { $0(target) }
  }

  // Merge two patches
  public func merged(with other: GenericPatch<Target>) -> GenericPatch<Target> {
    var result = GenericPatch<Target>()
    // Merge modifications (self first, then other)
    result.modifications = self.modifications + other.modifications
    return result
  }
}

// MARK: - TextField Specific Patch (Custom Composite Control)

/// Custom patch for ValidatedTextField (composite control with layout properties)
public struct TextFieldPatch: StylePatchProtocol {
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
}

// MARK: - Nested Builder for Chain Syntax

@dynamicMemberLookup
public final class NestedBuilder<Target> {
  private var modifications: [(Target) -> Void] = []

  public init() {}

  // For value types - need mutable copy
  public subscript<Value>(dynamicMember keyPath: WritableKeyPath<Target, Value>) -> ((Value) -> NestedBuilder) {
    { value in
      self.modifications.append { target in
        var mutableTarget = target
        mutableTarget[keyPath: keyPath] = value
      }
      return self
    }
  }

  // For reference types - direct modification
  public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<Target, Value>) -> ((Value) -> NestedBuilder) where Target: AnyObject {
    { value in
      self.modifications.append { target in
        target[keyPath: keyPath] = value
      }
      return self
    }
  }

  func apply(to target: Target) {
    modifications.forEach { $0(target) }
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

  // Custom method for GenericPatch
  @discardableResult
  public func custom<Target>(_ block: @escaping (Target) -> Void) -> ComponentStyleBuilder where Patch == GenericPatch<Target> {
    var patch = self.base
    patch.addModification(block)
    self.base = patch
    return self
  }

  // Custom method for TextFieldPatch
  @discardableResult
  public func custom(_ block: @escaping (ValidatedTextField) -> Void) -> ComponentStyleBuilder where Patch == TextFieldPatch {
    var patch = self.base
    patch.addModification(block)
    self.base = patch
    return self
  }

  // Configure nested objects for GenericPatch
  @discardableResult
  public func configure<Target, Nested>(_ keyPath: KeyPath<Target, Nested>, _ block: (NestedBuilder<Nested>) -> Void) -> ComponentStyleBuilder where Patch == GenericPatch<Target> {
    let nestedBuilder = NestedBuilder<Nested>()
    block(nestedBuilder)

    var patch = self.base
    patch.addModification { target in
      let nested = target[keyPath: keyPath]
      nestedBuilder.apply(to: nested)
    }
    self.base = patch
    return self
  }

  // Configure nested objects for TextFieldPatch
  @discardableResult
  public func configure<Nested>(_ keyPath: KeyPath<ValidatedTextField, Nested>, _ block: (NestedBuilder<Nested>) -> Void) -> ComponentStyleBuilder where Patch == TextFieldPatch {
    let nestedBuilder = NestedBuilder<Nested>()
    block(nestedBuilder)

    var patch = self.base
    patch.addModification { view in
      let nested = view[keyPath: keyPath]
      nestedBuilder.apply(to: nested)
    }
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

public struct StyleEngine<Patch: StylePatchProtocol, PrimaryState: Hashable, SecondaryState: Hashable> {
  private let style: ComponentStyle<Patch, PrimaryState, SecondaryState>

  public init(style: ComponentStyle<Patch, PrimaryState, SecondaryState>) {
    self.style = style
  }

  public func resolve(for primaryState: PrimaryState, _ secondaryState: SecondaryState) -> Patch {
    var resolved = style.base

    if let primaryPatch = style.primaryVariants[primaryState] {
      resolved = resolved.merged(with: primaryPatch)
    }

    if let secondaryPatch = style.secondaryVariants[secondaryState] {
      resolved = resolved.merged(with: secondaryPatch)
    }

    return resolved
  }
}

// MARK: - TextField Specialisations

public typealias TextFieldStyle = ComponentStyle<TextFieldPatch, InteractionState, ValidationPhase>
public typealias TextFieldStyleBuilder = ComponentStyleBuilder<TextFieldPatch, InteractionState, ValidationPhase>
public typealias TextFieldStyleEngine = StyleEngine<TextFieldPatch, InteractionState, ValidationPhase>
public typealias StyleBuilder = TextFieldStyleBuilder

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

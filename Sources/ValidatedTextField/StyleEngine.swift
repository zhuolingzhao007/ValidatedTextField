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

public struct StylePatch: StylePatchProtocol {
  // Layout
  public var containerPadding: CGFloat?
  public var horizontalPadding: CGFloat?
  public var accessorySpacing: CGFloat?
  public var verticalSpacing: CGFloat?

  // Visual styling
  public var borderWidth: CGFloat?
  public var borderColor: UIColor?
  public var cornerRadius: CGFloat?
  public var backgroundColor: UIColor?
  public var textColor: UIColor?
  public var textFont: UIFont?
  public var placeholderColor: UIColor?
  public var placeholderFont: UIFont?
  public var separatorColor: UIColor?
  public var errorColor: UIColor?
  public var errorFont: UIFont?
  public var keyboardType: UIKeyboardType?
  public var textAlignment: NSTextAlignment?

  public init() {}

  public func merged(with other: StylePatch) -> StylePatch {
    var result = self

    // Layout
    if let value = other.containerPadding { result.containerPadding = value }
    if let value = other.horizontalPadding { result.horizontalPadding = value }
    if let value = other.accessorySpacing { result.accessorySpacing = value }
    if let value = other.verticalSpacing { result.verticalSpacing = value }

    // Visual styling
    if let value = other.borderWidth { result.borderWidth = value }
    if let value = other.borderColor { result.borderColor = value }
    if let value = other.cornerRadius { result.cornerRadius = value }
    if let value = other.backgroundColor { result.backgroundColor = value }
    if let value = other.textColor { result.textColor = value }
    if let value = other.textFont { result.textFont = value }
    if let value = other.placeholderColor { result.placeholderColor = value }
    if let value = other.placeholderFont { result.placeholderFont = value }
    if let value = other.separatorColor { result.separatorColor = value }
    if let value = other.errorColor { result.errorColor = value }
    if let value = other.errorFont { result.errorFont = value }
    if let value = other.keyboardType { result.keyboardType = value }
    if let value = other.textAlignment { result.textAlignment = value }
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

@dynamicMemberLookup
public final class ComponentStyleBuilder<Patch: StylePatchProtocol, PrimaryState: Hashable, SecondaryState: Hashable> {
  private var base = Patch()
  private var primary: [PrimaryState: Patch] = [:]
  private var secondary: [SecondaryState: Patch] = [:]

  public init() {}

  public subscript<T>(dynamicMember key: WritableKeyPath<Patch, T?>) -> ((T) -> ComponentStyleBuilder) {
    { value in
      self.base[keyPath: key] = value
      return self
    }
  }

  @discardableResult
  public func onPrimaryState(_ state: PrimaryState, _ edit: (inout Patch) -> Void) -> ComponentStyleBuilder {
    var patch = primary[state] ?? Patch()
    edit(&patch)
    primary[state] = patch
    return self
  }

  @discardableResult
  public func onSecondaryState(_ state: SecondaryState, _ edit: (inout Patch) -> Void) -> ComponentStyleBuilder {
    var patch = secondary[state] ?? Patch()
    edit(&patch)
    secondary[state] = patch
    return self
  }

  public func build() -> ComponentStyle<Patch, PrimaryState, SecondaryState> {
    ComponentStyle(base: base, primaryVariants: primary, secondaryVariants: secondary)
  }
}

public extension ComponentStyleBuilder where PrimaryState == InteractionState {
  @discardableResult
  func onInteraction(_ state: InteractionState, _ edit: (inout Patch) -> Void) -> ComponentStyleBuilder {
    onPrimaryState(state, edit)
  }
}

public extension ComponentStyleBuilder where SecondaryState == ValidationPhase {
  @discardableResult
  func onValidation(_ state: ValidationPhase, _ edit: (inout Patch) -> Void) -> ComponentStyleBuilder {
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

public typealias TextFieldStyle = ComponentStyle<StylePatch, InteractionState, ValidationPhase>
public typealias TextFieldStyleBuilder = ComponentStyleBuilder<StylePatch, InteractionState, ValidationPhase>
public typealias TextFieldStyleEngine = StyleEngine<StylePatch, InteractionState, ValidationPhase>
public typealias StyleBuilder = TextFieldStyleBuilder

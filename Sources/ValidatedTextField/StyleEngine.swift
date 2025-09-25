//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//
import UIKit

// MARK: - Style Engine

public struct StylePatch {
  // Layout
  public var containerPadding: CGFloat?
  public var horizontalPadding: CGFloat?
  public var accessorySpacing: CGFloat?
  public var verticalSpacing: CGFloat?

  // Original properties
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
  func merged(with other: StylePatch) -> StylePatch {
    var r = self
    // Layout
    if let v = other.containerPadding { r.containerPadding = v }
    if let v = other.horizontalPadding { r.horizontalPadding = v }
    if let v = other.accessorySpacing { r.accessorySpacing = v }
    if let v = other.verticalSpacing { r.verticalSpacing = v }

    // Original
    if let v = other.borderWidth { r.borderWidth = v }
    if let v = other.borderColor { r.borderColor = v }
    if let v = other.cornerRadius { r.cornerRadius = v }
    if let v = other.backgroundColor { r.backgroundColor = v }
    if let v = other.textColor { r.textColor = v }
    if let v = other.textFont { r.textFont = v }
    if let v = other.placeholderColor { r.placeholderColor = v }
    if let v = other.placeholderFont { r.placeholderFont = v }
    if let v = other.separatorColor { r.separatorColor = v }
    if let v = other.errorColor { r.errorColor = v }
    if let v = other.errorFont { r.errorFont = v }
    if let v = other.keyboardType { r.keyboardType = v }
    if let v = other.textAlignment { r.textAlignment = v }
    return r
  }
}

public struct TextFieldStyle {
  public var base: StylePatch = .init()
  public var interactionVariants: [InteractionState: StylePatch] = [:]
  public var validationVariants: [ValidationPhase: StylePatch] = [:]
  public init() {}
}

@dynamicMemberLookup
public final class StyleBuilder {
  private var base = StylePatch()
  private var interaction: [InteractionState: StylePatch] = [:]
  private var validation: [ValidationPhase: StylePatch] = [:]

  public init() {}

  public subscript<T>(dynamicMember key: WritableKeyPath<StylePatch, T?>) -> (
    (T) -> StyleBuilder
  ) {
    { value in
      self.base[keyPath: key] = value
      return self
    }
  }

  public func onInteraction(_ s: InteractionState, _ edit: (Patch) -> Void)
    -> StyleBuilder
  {
    let p = interaction[s] ?? StylePatch()
    let patch = Patch(patch: p)
    edit(patch)
    interaction[s] = patch.finalPatch
    return self
  }

  public func onValidation(_ v: ValidationPhase, _ edit: (Patch) -> Void)
    -> StyleBuilder
  {
    let p = validation[v] ?? StylePatch()
    let patch = Patch(patch: p)
    edit(patch)
    validation[v] = patch.finalPatch
    return self
  }

  // Nested patch editor - Safe implementation with value semantics
  public struct Patch {
    private var currentPatch: StylePatch

    init(patch: StylePatch) {
      self.currentPatch = patch
    }

    var finalPatch: StylePatch { currentPatch }

    @discardableResult
    public func callAsFunction(_ block: (inout StylePatch) -> Void) -> Patch {
      var newPatch = Patch(patch: currentPatch)
      block(&newPatch.currentPatch)
      return newPatch
    }

    public subscript<T>(dynamicMember key: WritableKeyPath<StylePatch, T?>) -> (
      (T) -> Patch
    ) {
      { value in
        var newPatch = Patch(patch: self.currentPatch)
        newPatch.currentPatch[keyPath: key] = value
        return newPatch
      }
    }
  }

  public func build() -> TextFieldStyle {
    var t = TextFieldStyle()
    t.base = base
    t.interactionVariants = interaction
    t.validationVariants = validation
    return t
  }

}

public struct StyleEngine {
  private let style: TextFieldStyle
  public init(style: TextFieldStyle) { self.style = style }

  public func resolve(for i: InteractionState, _ v: ValidationPhase)
    -> StylePatch
  {
    style.base
      .merged(with: style.interactionVariants[i] ?? .init())
      .merged(with: style.validationVariants[v] ?? .init())
  }
}

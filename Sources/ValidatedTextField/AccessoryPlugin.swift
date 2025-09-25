//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//
import UIKit

// MARK: - Accessory

public enum AccessoryPlacement { case leading, trailing }

public struct TextProxy {
  public let get: () -> String
  public let set: (String) -> Void
  public let replace: ((inout String) -> Void) -> Void
  public init(
    get: @escaping () -> String,
    set: @escaping (String) -> Void,
    replace: @escaping ((inout String) -> Void) -> Void
  ) {
    self.get = get
    self.set = set
    self.replace = replace
  }
}

public protocol AccessoryPlugin: AnyObject {
  var view: UIView { get }
  var placement: AccessoryPlacement { get }
  func bind(text: TextProxy)
  func apply(interaction: InteractionState, validation: ValidationState)

  /// Called when accessory needs to notify container to relayout
  /// - Note: Default implementation is empty, specific implementation provided by container
  func invalidateContainerLayout()
}

extension AccessoryPlugin {
  public var placement: AccessoryPlacement { .trailing }
  public func bind(text: TextProxy) {}
  public func apply(interaction: InteractionState, validation: ValidationState) {}
  public func invalidateContainerLayout() {
    // Default implementation: search upwards through superview for AccessoryContainer
    var superview = view.superview
    while superview != nil {
      if let container = superview as? AccessoryContainer {
        container.invalidateAccessoryLayout()
        return
      }
      superview = superview?.superview
    }
  }
}

// MARK: - Container Protocol
/// Protocol provided to accessory for notifying container to relayout
public protocol AccessoryContainer: AnyObject {
  func invalidateAccessoryLayout()
}

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

  /// 当 accessory 需要通知容器重新布局时调用
  /// - Note: 默认实现为空，具体实现由容器提供
  func invalidateContainerLayout()
}

extension AccessoryPlugin {
  public var placement: AccessoryPlacement { .trailing }
  public func bind(text: TextProxy) {}
  public func apply(interaction: InteractionState, validation: ValidationState) {}
  public func invalidateContainerLayout() {
    // 默认实现：通过 superview 向上查找 AccessoryContainer
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
/// 提供给 accessory 用来通知容器重新布局的协议
public protocol AccessoryContainer: AnyObject {
  func invalidateAccessoryLayout()
}

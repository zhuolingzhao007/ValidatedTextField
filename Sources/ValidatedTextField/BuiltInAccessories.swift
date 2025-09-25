//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//
import UIKit

// MARK: - Accessory Example

public final class ClearButtonAccessory: AccessoryPlugin {
  public let view: UIView
  public let placement: AccessoryPlacement = .trailing
  private var text: TextProxy?

  public init() {

    let button = UIButton()
    let image: UIImage = .icon(.iconXSmallFilled, fontSize: 14, color: .Icon.tertiary)
    button.setImage(image, for: .normal)

    let containerView = UIView()
    containerView.addSubview(button)

    button.center = .init(x: 15, y: 18)
    button.bounds = .init(origin: .zero, size: .init(width: 34, height: 36))
    containerView.frame = CGRectMake(0, 0, 34, 36)

    self.view = containerView
    button.addTarget(self, action: #selector(clearText), for: .touchUpInside)
    view.isHidden = true
  }

  @objc private func clearText() {
    text?.set("")
  }

  public func bind(text: TextProxy) { self.text = text }

  public func apply(interaction: InteractionState, validation: ValidationState) {
    if interaction == .editing {
      view.isHidden = text?.get().isEmpty ?? true
    } else {
      view.isHidden = true
    }
  }
}

// MARK: - Label Accessory Example

public final class LabelAccessory: AccessoryPlugin {
  public let view: UIView
  public let placement: AccessoryPlacement = .leading
  private let label: UILabel
  private let originalColor: UIColor

  public init(
    text: String, font: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium),
    color: UIColor = .secondaryLabel
  ) {
    originalColor = color

    let label = UILabel()
    label.text = text
    label.font = font
    label.textColor = color
    label.textAlignment = .left
    label.numberOfLines = 1
    label.sizeToFit()

    let containerView = UIView()
    containerView.addSubview(label)

    // Use frame layout
    label.frame = CGRect(
      x: 0, y: (36 - label.frame.height) / 2, width: label.frame.width, height: label.frame.height)
    containerView.frame = CGRect(x: 0, y: 0, width: label.frame.width + 8, height: 36)  // padding 0- 8

    self.view = containerView
    self.label = label
  }

  public func bind(text: TextProxy) {
    // Fixed text, no need to bind
  }

  public func apply(interaction: InteractionState, validation: ValidationState) {

  }
}

// MARK: - Custom View Accessory

public final class CustomViewAccessory: AccessoryPlugin {
  public let view: UIView
  public let placement: AccessoryPlacement
  private var text: TextProxy?
  private let stateHandler: ((InteractionState, ValidationState) -> Void)?
  private let customView: UIView
  private var boundsObservation: NSKeyValueObservation?

  /// Initialize custom view accessory
  public init(
    customView: UIView,
    placement: AccessoryPlacement = .trailing,
    stateHandler: ((InteractionState, ValidationState) -> Void)? = nil
  ) {
    self.placement = placement
    self.stateHandler = stateHandler
    self.customView = customView

    self.view = customView
    self.view.isHidden = false

    setupBoundsObservation()
  }

  private func setupBoundsObservation() {
    boundsObservation = customView.observe(\.bounds, options: [.new, .old]) {
      [weak self] (view, change) in
      guard let self = self else { return }

      guard let oldBounds = change.oldValue, let newBounds = change.newValue else { return }

      if oldBounds.size != newBounds.size {
        DispatchQueue.main.async {
          self.handleCustomViewSizeChange(newSize: newBounds.size)
        }
      }
    }
  }

  private func handleCustomViewSizeChange(newSize: CGSize) {
    invalidateContainerLayout()
  }

  /// Update view width
  public func updateWidth(_ width: CGFloat) {
    customView.frame = CGRect(x: 0, y: 0, width: width, height: customView.frame.height)
    customView.layoutIfNeeded()
    invalidateContainerLayout()
  }

  /// Update view size
  public func updateSize(width: CGFloat, height: CGFloat? = nil) {
    let newHeight = height ?? customView.frame.height
    customView.frame = CGRect(x: 0, y: 0, width: width, height: newHeight)
    customView.layoutIfNeeded()
    invalidateContainerLayout()
  }

  /// Get current view width
  public var currentWidth: CGFloat {
    return customView.frame.width
  }

  /// Get current view height
  public var currentHeight: CGFloat {
    return customView.frame.height
  }

  public func bind(text: TextProxy) {
    self.text = text
  }

  public func apply(interaction: InteractionState, validation: ValidationState) {
    // Call state handler closure (if provided)
    stateHandler?(interaction, validation)
  }

  deinit {
    // Release KVO observer
    boundsObservation?.invalidate()
    boundsObservation = nil
  }
}

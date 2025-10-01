//
//  UIKitStyleBuilders.swift
//  ValidatedTextField
//
//  Created by zhuolingzhao on 10/1/25.
//

import UIKit

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

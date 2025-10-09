//
//  ComponentStyle.swift
//  ValidatedTextField
//
//  Created by zhuolingzhao on 10/1/25.
//

import Foundation

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

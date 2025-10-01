//
//  StylePatchProtocol.swift
//  ValidatedTextField
//
//  Created by zhuolingzhao on 10/1/25.
//

import Foundation

// MARK: - Style Infrastructure

public protocol StylePatchProtocol {
  associatedtype Target
  init()
  mutating func addModification(_ modification: @escaping (Target) -> Void)
  func merged(with other: Self) -> Self
}

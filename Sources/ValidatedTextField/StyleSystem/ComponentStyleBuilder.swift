//
//  ComponentStyleBuilder.swift
//  ValidatedTextField
//
//  Created by zhuolingzhao on 10/1/25.
//

import Foundation

// MARK: - Generic ComponentStyleBuilder

@dynamicMemberLookup
public final class ComponentStyleBuilder<Patch: StylePatchProtocol, PrimaryState: Hashable, SecondaryState: Hashable> {
  internal var base = Patch()
  private var primary: [PrimaryState: Patch] = [:]
  private var secondary: [SecondaryState: Patch] = [:]

  public init() {}

  // Unified dynamic member lookup for reference types (classes)
  public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<Patch.Target, Value>) -> ((Value) -> ComponentStyleBuilder) where Patch.Target: AnyObject {
    { value in
      var patch = self.base
      patch.addModification { target in
        target[keyPath: keyPath] = value
      }
      self.base = patch
      return self
    }
  }

  // Unified dynamic member lookup for value types (structs)
  public subscript<Value>(dynamicMember keyPath: WritableKeyPath<Patch.Target, Value>) -> ((Value) -> ComponentStyleBuilder) {
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

  // Custom method - unified for all patch types
  @discardableResult
  public func custom(_ block: @escaping (Patch.Target) -> Void) -> ComponentStyleBuilder {
    var patch = self.base
    patch.addModification(block)
    self.base = patch
    return self
  }

  // Configure nested objects with NestedBuilder
  @discardableResult
  public func configure<NestedTarget>(_ keyPath: KeyPath<Patch.Target, NestedTarget>, _ block: (NestedBuilder<NestedTarget>) -> NestedBuilder<NestedTarget>) -> ComponentStyleBuilder where Patch.Target: AnyObject {
    let nestedBuilder = NestedBuilder<NestedTarget>()
    let modifiedBuilder = block(nestedBuilder)

    var patch = self.base
    patch.addModification { target in
      let nested = target[keyPath: keyPath]
      modifiedBuilder.apply(to: nested)
    }
    self.base = patch
    return self
  }

  @discardableResult
  public func onPrimaryState(_ state: PrimaryState, _ edit: (ComponentStyleBuilder) -> ComponentStyleBuilder) -> ComponentStyleBuilder {
    let builder = ComponentStyleBuilder<Patch, PrimaryState, SecondaryState>()
    let modifiedBuilder = edit(builder)
    primary[state] = modifiedBuilder.base
    return self
  }

  @discardableResult
  public func onSecondaryState(_ state: SecondaryState, _ edit: (ComponentStyleBuilder) -> ComponentStyleBuilder) -> ComponentStyleBuilder {
    let builder = ComponentStyleBuilder<Patch, PrimaryState, SecondaryState>()
    let modifiedBuilder = edit(builder)
    secondary[state] = modifiedBuilder.base
    return self
  }

  public func build() -> ComponentStyle<Patch, PrimaryState, SecondaryState> {
    ComponentStyle(base: base, primaryVariants: primary, secondaryVariants: secondary)
  }
}

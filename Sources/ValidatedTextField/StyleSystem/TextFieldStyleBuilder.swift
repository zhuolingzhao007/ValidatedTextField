//
//  TextFieldStyleBuilder.swift
//  ValidatedTextField
//
//  Created by zhuolingzhao on 10/1/25.
//

import Foundation

// MARK: - TextField Specialisations

public typealias TextFieldStyle = ComponentStyle<TextFieldPatch, InteractionState, ValidationPhase>
public typealias TextFieldStyleBuilder = ComponentStyleBuilder<TextFieldPatch, InteractionState, ValidationPhase>
public typealias StyleBuilder = TextFieldStyleBuilder

// MARK: - TextField Specific Extensions

public extension ComponentStyleBuilder where PrimaryState == InteractionState {
  @discardableResult
  func onInteraction(_ state: InteractionState, _ edit: (ComponentStyleBuilder) -> ComponentStyleBuilder) -> ComponentStyleBuilder {
    onPrimaryState(state, edit)
  }
}

public extension ComponentStyleBuilder where SecondaryState == ValidationPhase {
  @discardableResult
  func onValidation(_ state: ValidationPhase, _ edit: (ComponentStyleBuilder) -> ComponentStyleBuilder) -> ComponentStyleBuilder {
    onSecondaryState(state, edit)
  }
}

// MARK: - Layout Configuration Extension

public extension ComponentStyleBuilder where Patch == TextFieldPatch {
  /// Layout configuration helper for TextFieldPatch
  @discardableResult
  func layout(_ block: (inout TextFieldPatch) -> Void) -> ComponentStyleBuilder {
    var patch = self.base
    block(&patch)
    self.base = patch
    return self
  }
}

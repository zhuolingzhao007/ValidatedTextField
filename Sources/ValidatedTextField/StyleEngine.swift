//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//
import UIKit

// MARK: - Style Patch

public protocol StylePatchProtocol {
    init()
    func merged(with other: Self) -> Self
}

public struct StylePatch: StylePatchProtocol {
    public var applicators: [(Any) -> Void] = []

    public init() {}

    @discardableResult
    public mutating func set<Component, Value>(_ keyPath: WritableKeyPath<Component, Value>, to value: Value) -> Self {
        applicators.append { component in
            if var component = component as? Component {
                component[keyPath: keyPath] = value
            }
        }
        return self
    }

    public func merged(with other: StylePatch) -> StylePatch {
        var result = self
        result.applicators.append(contentsOf: other.applicators)
        return result
    }

    public func apply<Component>(to component: Component) {
        for applicator in applicators {
            applicator(component)
        }
    }
}

// MARK: - Core Style Component & Engine

public struct ComponentStyle<Patch: StylePatchProtocol, PrimaryState: Hashable, SecondaryState: Hashable> {
    public var base: Patch
    public var primaryVariants: [PrimaryState: Patch]
    public var secondaryVariants: [SecondaryState: Patch]

    public init(base: Patch = .init(), primaryVariants: [PrimaryState: Patch] = [:], secondaryVariants: [SecondaryState: Patch] = [:]) {
        self.base = base
        self.primaryVariants = primaryVariants
        self.secondaryVariants = secondaryVariants
    }
}

public struct StyleEngine<Patch: StylePatchProtocol, PrimaryState: Hashable, SecondaryState: Hashable> {
    private let style: ComponentStyle<Patch, PrimaryState, SecondaryState>

    public init(style: ComponentStyle<Patch, PrimaryState, SecondaryState>) {
        self.style = style
    }

    public func resolve(for primaryState: PrimaryState, _ secondaryState: SecondaryState) -> Patch {
        var resolved = style.base
        if let primaryPatch = style.primaryVariants[primaryState] { resolved = resolved.merged(with: primaryPatch) }
        if let secondaryPatch = style.secondaryVariants[secondaryState] { resolved = resolved.merged(with: secondaryPatch) }
        return resolved
    }
}

// MARK: - Dynamic Property Styler

/// A proxy that allows chaining key paths to apply styles dynamically.
@dynamicMemberLookup
public struct PropertyStyler<Root, Current> {
    let builder: ComponentStyleBuilder<StylePatch, InteractionState, ValidationPhase>
    let path: PartialKeyPath<Root>

    /// Handles setting a value on a nested property (e.g., `builder.textField.textColor(.blue)`).
    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<Current, Value>) -> ((Value) -> ComponentStyleBuilder<StylePatch, InteractionState, ValidationPhase>) {
        return { value in
            // Append the final property's keyPath to the current path to get the full path from the root.
            if let fullPath = self.path.appending(path: keyPath) as? WritableKeyPath<Root, Value> {
                self.builder.set(fullPath, to: value)
            }
            return self.builder
        }
    }

    /// Handles further traversal down the key path chain (e.g., `builder.layer.shadow`).
    public subscript<Next>(dynamicMember keyPath: KeyPath<Current, Next>) -> PropertyStyler<Root, Next> {
        let newPath = self.path.appending(path: keyPath)!
        return PropertyStyler<Root, Next>(builder: self.builder, path: newPath)
    }
}

// MARK: - StyleBuilder

@dynamicMemberLookup
public final class ComponentStyleBuilder<Patch: StylePatchProtocol, PrimaryState: Hashable, SecondaryState: Hashable> where Patch == StylePatch {
    private var base = Patch()
    private var primary: [PrimaryState: Patch] = [:]
    private var secondary: [SecondaryState: Patch] = [:]

    public init() {}

    /// Handles setting a value on a direct property of the root component (`ValidatedTextField`).
    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<ValidatedTextField, Value>) -> ((Value) -> Self) {
        return { value in
            self.set(keyPath, to: value)
            return self
        }
    }

    /// Handles the start of a key path chain to a nested property (e.g., `builder.textField`).
    public subscript<Next>(dynamicMember keyPath: KeyPath<ValidatedTextField, Next>) -> PropertyStyler<ValidatedTextField, Next> {
        return PropertyStyler(builder: self, path: keyPath)
    }
    
    /// The core method to add a style applicator to the patch.
    /// This is public so it can be called by the `PropertyStyler`.
    @discardableResult
    public func set<Root, Value>(_ keyPath: WritableKeyPath<Root, Value>, to value: Value) -> Self {
        base.set(keyPath, to: value)
        return self
    }
    
    /// Applies a custom configuration block to the component.
    @discardableResult
    public func apply<Component>(_ block: @escaping (Component) -> Void) -> Self {
        let applicator: (Any) -> Void = { component in
            if let component = component as? Component {
                block(component)
            }
        }
        base.applicators.append(applicator)
        return self
    }

    // --- State modification methods ---
    @discardableResult
    public func onPrimaryState(_ state: PrimaryState, _ edit: (inout Patch) -> Void) -> Self {
        var patch = primary[state] ?? Patch()
        edit(&patch)
        primary[state] = patch
        return self
    }

    @discardableResult
    public func onSecondaryState(_ state: SecondaryState, _ edit: (inout Patch) -> Void) -> Self {
        var patch = secondary[state] ?? Patch()
        edit(&patch)
        secondary[state] = patch
        return self
    }

    public func build() -> ComponentStyle<Patch, PrimaryState, SecondaryState> {
        ComponentStyle(base: base, primaryVariants: primary, secondaryVariants: secondary)
    }
}

// MARK: - TextField Specialisations

public typealias TextFieldStyle = ComponentStyle<StylePatch, InteractionState, ValidationPhase>
public typealias TextFieldStyleBuilder = ComponentStyleBuilder<StylePatch, InteractionState, ValidationPhase>
public typealias TextFieldStyleEngine = StyleEngine<StylePatch, InteractionState, ValidationPhase>
public typealias StyleBuilder = TextFieldStyleBuilder

public extension ComponentStyleBuilder where PrimaryState == InteractionState {
    @discardableResult
    func onInteraction(_ state: InteractionState, _ edit: (inout Patch) -> Void) -> Self {
        onPrimaryState(state, edit)
    }
}

public extension ComponentStyleBuilder where SecondaryState == ValidationPhase {
    @discardableResult
    func onValidation(_ state: ValidationPhase, _ edit: (inout Patch) -> Void) -> Self {
        onSecondaryState(state, edit)
    }
}

// MARK: - Default Style Definition
public extension TextFieldStyle {
    static var `default`: TextFieldStyle {
        let builder = StyleBuilder()
        
        // Define default styles using the new dynamic API
        builder
            .backgroundColor(.clear)
            .layer.cornerRadius(8)
            .layer.borderWidth(1)
            .layer.borderColor(UIColor.systemGray4.cgColor)
            .textField.font(.systemFont(ofSize: 16))
            .textField.textColor(.label)
        
        // Use apply for complex configurations like placeholder
        builder.apply { (field: ValidatedTextField) in
            field.setPlaceholderColor(.placeholderText)
            field.setErrorColor(.systemRed)
            field.setErrorFont(.systemFont(ofSize: 12))
            field.setSeparatorColor(.systemGray4)
            field.containerPadding = 12
            field.horizontalPadding = 16
            field.accessorySpacing = 8
            field.verticalSpacing = 6
        }

        builder.onInteraction(.editing) { patch in
            patch.set(\.layer.borderColor, to: UIColor.systemBlue.cgColor)
        }
        
        builder.onInteraction(.disabled) { patch in
            patch.set(\.backgroundColor, to: UIColor.systemGray6)
               .set(\.textField.textColor, to: UIColor.systemGray)
        }
        
        builder.onValidation(.invalid) { patch in
            patch.set(\.layer.borderColor, to: UIColor.systemRed.cgColor)
               .set(\.textField.textColor, to: UIColor.systemRed)
        }
        return builder.build()
    }
}

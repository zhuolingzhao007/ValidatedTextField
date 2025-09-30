//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//
import UIKit

// MARK: - Core UI

public final class ValidatedTextField: UIView {

    // MARK: - Cursor Position
    public enum CursorPosition {
        case `default`
        case start
        case end
    }
    
    // MARK: - Public Properties
    
    // Configuration
    public var strategy: ValidationStrategy {
        didSet { processValidation(triggeredByChange: false) }
    }
    public var accessories: [AccessoryPlugin] = [] {
        didSet { reloadAccessories() }
    }
    public var placeholderProvider: ((InteractionState, ValidationPhase) -> String?)? {
        didSet { render() }
    }
    public var onValidationChanged: ((ValidationState) -> Void)?
    public var cursorPosition: CursorPosition = .default

    // Direct Access
    public var text: String {
        get { textField.text ?? "" }
        set { setTextWithFormatting(newValue) }
    }
    public var placeholder: String? {
        get { _placeholder }
        set {
            _placeholder = newValue
            render()
        }
    }
    public var isEnabled: Bool {
        didSet {
            textField.isEnabled = isEnabled
            iState = isEnabled ? .idle : .disabled
            updateState()
        }
    }
    
    // MARK: - Styling Properties (managed by StyleEngine)
    var containerPadding: CGFloat = 16
    var horizontalPadding: CGFloat = 0
    var accessorySpacing: CGFloat = 0
    var verticalSpacing: CGFloat = 6
    
    private var _placeholder: String?
    private var _placeholderColor: UIColor?
    private var _placeholderFont: UIFont?
    private var _errorColor: UIColor?
    private var _errorFont: UIFont?
    
    // MARK: - Private State
    private(set) var iState: InteractionState = .idle
    private(set) var vState: ValidationState = .none {
        didSet { if oldValue != vState { onValidationChanged?(vState) } }
    }
    private var styleEngine: TextFieldStyleEngine = .init(style: TextFieldStyle.default)
    private var didCommitOnce = false

    // MARK: - UI Components
    public let textField = UITextField()
    private let separator = UIView()
    private let errorLabel = UILabel()
    private var leadingViews: [UIView] = []
    private var trailingViews: [UIView] = []

    // MARK: - Initialization
    public override init(frame: CGRect) {
        self.strategy = .init()
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        self.strategy = .init()
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setupUI()
        attachHandlers()
        updateState()
    }

    private func setupUI() {
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        layer.masksToBounds = true

        addSubview(textField)
        addSubview(separator)
        addSubview(errorLabel)

        textField.borderStyle = .none
        textField.clearButtonMode = .never
    }
    
    // MARK: - Styling Configuration
    
    public func configureStyle(_ block: (StyleBuilder) -> Void) {
        let builder = StyleBuilder()
        block(builder)
        // Merge user-defined style on top of the default style
        let finalStyle = TextFieldStyle.default.base.merged(with: builder.build().base)
        let finalPrimary = TextFieldStyle.default.primaryVariants.merging(builder.build().primaryVariants) { (_, new) in new }
        let finalSecondary = TextFieldStyle.default.secondaryVariants.merging(builder.build().secondaryVariants) { (_, new) in new }
        
        let mergedComponentStyle = ComponentStyle(base: finalStyle, primaryVariants: finalPrimary, secondaryVariants: finalSecondary)
        
        styleEngine = TextFieldStyleEngine(style: mergedComponentStyle)
        render()
    }
}

// MARK: - Layout & Sizing
extension ValidatedTextField {
    public override func layoutSubviews() {
        super.layoutSubviews()
        _ = performLayout(for: self.bounds.width)
    }

    public override var intrinsicContentSize: CGSize {
        let height = performLayout(for: bounds.width)
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let height = performLayout(for: size.width)
        return CGSize(width: size.width, height: height)
    }

    private func performLayout(for width: CGFloat) -> CGFloat {
        let font = textField.font ?? .systemFont(ofSize: 17)
        let textFieldHeight: CGFloat = ceil(font.lineHeight)

        textField.frame = CGRect(x: 0, y: containerPadding, width: width, height: textFieldHeight)

        let visibleLeadingViews = leadingViews.filter { !$0.isHidden }
        var currentX: CGFloat = horizontalPadding
        var lastLeadingView: UIView?
        for view in visibleLeadingViews {
            view.frame.origin = CGPoint(x: currentX, y: textField.frame.midY - view.frame.height / 2)
            currentX += view.frame.width + accessorySpacing
            lastLeadingView = view
        }

        let visibleTrailingViews = trailingViews.filter { !$0.isHidden }
        currentX = width - horizontalPadding
        var lastTrailingView: UIView?
        for view in visibleTrailingViews.reversed() {
            currentX -= view.frame.width
            view.frame.origin = CGPoint(x: currentX, y: textField.frame.midY - view.frame.height / 2)
            currentX -= accessorySpacing
            lastTrailingView = view
        }
        
        let textFieldX = lastLeadingView?.frame.maxX.advanced(by: accessorySpacing) ?? horizontalPadding
        let textFieldEndX = lastTrailingView?.frame.minX.advanced(by: -accessorySpacing) ?? width - horizontalPadding
        
        textField.frame = CGRect(
            x: textFieldX,
            y: containerPadding,
            width: max(0, textFieldEndX - textFieldX),
            height: textFieldHeight
        )
        
        let separatorY = textField.frame.maxY + containerPadding
        separator.frame = CGRect(x: 0, y: separatorY, width: width, height: 0.5)

        if !errorLabel.isHidden {
            errorLabel.frame = CGRect(x: 0, y: separator.frame.maxY + verticalSpacing, width: width, height: 0)
            errorLabel.sizeToFit()
            errorLabel.frame.size.width = width
            return errorLabel.frame.maxY
        } else {
            return separator.frame.maxY
        }
    }
}


// MARK: - State Management & Rendering
extension ValidatedTextField {
    private func attachHandlers() {
        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
        textField.delegate = self
    }

    @objc private func editingDidBegin() { iState = .editing; updateState() }
    @objc private func editingDidEnd() {
        iState = isEnabled ? .idle : .disabled
        didCommitOnce = true
        updateState()
        processValidation(triggeredByChange: false, committed: true)
    }
    
    private func updateState() {
        render()
        broadcast()
    }

    private func render() {
        let patch = styleEngine.resolve(for: iState, vState.phase)
        
        UIView.animate(withDuration: 0.15) {
            patch.apply(to: self)
            self.updatePlaceholder()
            self.updateErrorLabel()
            
            self.setNeedsLayout()
            self.invalidateIntrinsicContentSize()
        }
    }

    private func broadcast() {
        accessories.forEach { $0.apply(interaction: iState, validation: vState) }
        setNeedsLayout()
    }
    
    private func updatePlaceholder() {
        let phText = self.placeholderProvider?(self.iState, self.vState.phase) ?? self._placeholder
        guard let ph = phText else {
            self.textField.attributedPlaceholder = nil; return
        }
        
        var attrs: [NSAttributedString.Key: Any] = [:]
        if let color = _placeholderColor { attrs[.foregroundColor] = color }
        if let font = _placeholderFont ?? textField.font { attrs[.font] = font }
        self.textField.attributedPlaceholder = NSAttributedString(string: ph, attributes: attrs)
    }

    private func updateErrorLabel() {
        switch self.vState {
        case .invalid(let msg):
            errorLabel.isHidden = false
            errorLabel.text = msg
            errorLabel.textColor = _errorColor ?? .systemRed
            errorLabel.font = _errorFont ?? .systemFont(ofSize: 12)
        default:
            errorLabel.isHidden = true
            errorLabel.text = nil
        }
    }
}


// MARK: - Internal Styling Helpers
extension ValidatedTextField {
    func setPlaceholderColor(_ color: UIColor?) { _placeholderColor = color }
    func setPlaceholderFont(_ font: UIFont?) { _placeholderFont = font }
    func setErrorColor(_ color: UIColor?) { _errorColor = color }
    func setErrorFont(_ font: UIFont?) { _errorFont = font }
    func setSeparatorColor(_ color: UIColor?) { separator.backgroundColor = color }
}


// MARK: - Validation Logic & Delegate Implementations
extension ValidatedTextField {
    private func setTextWithFormatting(_ newText: String) {
        let currentText = textField.text ?? ""
        let range = NSRange(location: 0, length: currentText.count)
        _ = textField(textField, shouldChangeCharactersIn: range, replacementString: newText)
    }

    private func processValidation(triggeredByChange: Bool, committed: Bool = false) {
        let shouldValidate: Bool
        switch strategy.trigger {
        case .onChange: shouldValidate = triggeredByChange
        case .onCommit: shouldValidate = committed
        case .afterCommitThenChange: shouldValidate = committed || (didCommitOnce && triggeredByChange)
        }
        guard shouldValidate else { return }
        
        let raw = textField.text ?? ""
        vState = strategy.validator?.validate(raw) ?? .valid
        updateState()
    }
}

extension ValidatedTextField: AccessoryContainer {
    public func invalidateAccessoryLayout() { setNeedsLayout(); layoutIfNeeded() }
    private func reloadAccessories() {
        leadingViews.forEach { $0.removeFromSuperview() }; trailingViews.forEach { $0.removeFromSuperview() }
        leadingViews.removeAll(); trailingViews.removeAll()
        guard !accessories.isEmpty else { return }
        let proxy = TextProxy(
            get: { [weak self] in self?.text ?? "" },
            set: { [weak self] newText in self?.setTextWithFormatting(newText) },
            replace: { [weak self] transform in var current = self?.text ?? ""; transform(&current); self?.setTextWithFormatting(current) }
        )
        for plugin in accessories {
            plugin.bind(text: proxy)
            switch plugin.placement {
            case .leading: leadingViews.append(plugin.view); addSubview(plugin.view)
            case .trailing: trailingViews.append(plugin.view); addSubview(plugin.view)
            }
        }
        broadcast()
    }
}

extension ValidatedTextField: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let formatter = strategy.formatter {
            let currentText = textField.text ?? ""
            guard let range = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: range, with: string)
            let change = TextChange(previousText: currentText, newText: newText, changeRange: range, replacementString: string, cursorPosition: range.lowerBound.utf16Offset(in: currentText) + string.count)
            let result = formatter.format(change: change)
            textField.text = result.formattedText
            if let newPosition = result.cursorPosition, let pos = textField.position(from: textField.beginningOfDocument, offset: min(newPosition, result.formattedText.count)) {
                textField.selectedTextRange = textField.textRange(from: pos, to: pos)
            }
            processValidation(triggeredByChange: true); broadcast(); return false
        }
        DispatchQueue.main.async { self.processValidation(triggeredByChange: true) }; broadcast(); return true
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool { textField.resignFirstResponder(); return true }
    public func textFieldDidChangeSelection(_ textField: UITextField) {
        switch cursorPosition {
        case .default: break
        case .end:
            if let end = textField.position(from: textField.endOfDocument, offset: 0) { textField.selectedTextRange = textField.textRange(from: end, to: end) }
        case .start:
            if let start = textField.position(from: textField.beginningOfDocument, offset: 0) { textField.selectedTextRange = textField.textRange(from: start, to: start) }
        }
    }
}

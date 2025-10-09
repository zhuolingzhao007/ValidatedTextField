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
        case `default`  // Default (end of text)
        case start  // Start of text
        case end  // End of text (same as default, but explicit)
    }

    // MARK: - Layout Constants
    private enum Layout {
        static let containerPadding: CGFloat = 16
        static let horizontalPadding: CGFloat = 0
        static let accessorySpacing: CGFloat = 0
        static let verticalSpacing: CGFloat = 6
        static let separatorHeight: CGFloat = 0.5
        static let errorFontSize: CGFloat = 12
        static let cornerRadius: CGFloat = 0
    }

    // Public
    public var strategy: ValidationStrategy {
        didSet { processValidation(triggeredByChange: false) }
    }
    public var accessories: [AccessoryPlugin] = [] {
        didSet { reloadAccessories() }
    }
    public var text: String {
        get { textField.text ?? "" }
        set { setTextWithFormatting(newValue) }
    }
    public var placeholder: String? {
        get { textField.attributedPlaceholder?.string ?? textField.placeholder }
        set { textField.placeholder = newValue }
    }
    public var keyboardType: UIKeyboardType {
        get { textField.keyboardType }
        set { textField.keyboardType = newValue }
    }
    public var placeholderProvider: ((InteractionState, ValidationPhase) -> String?)? {
        didSet { render() }
    }
    public var isEnabled: Bool = true {
        didSet {
            textField.isEnabled = isEnabled
            iState = isEnabled ? .idle : .disabled
            updateState()
        }
    }
    public func configureStyle(_ block: (StyleBuilder) -> Void) {
        let builder = StyleBuilder()
        block(builder)
        styleEngine = builder.build()
        render()
    }
    public var onValidationChanged: ((ValidationState) -> Void)?
    public var cursorPosition: CursorPosition = .default

    // Private
    private(set) var iState: InteractionState = .idle
    private(set) var vState: ValidationState = .none {
        didSet {
            if oldValue != vState {
                onValidationChanged?(vState)
            }
        }
    }
    private var styleEngine: TextFieldStyle = .init()
    private var didCommitOnce = false

    private var previousAccessoryWidth: CGFloat = 0

    private func calculateVisibleAccessoryWidth() -> CGFloat {
        let patch = styleEngine.resolve(for: iState, vState.phase)
        let spacing = patch.accessorySpacing ?? Layout.accessorySpacing

        // Calculate leading view width
        let visibleLeadingViews = leadingViews.filter { !$0.isHidden }
        let leadingWidth: CGFloat = calculateViewsWidth(
            views: visibleLeadingViews, spacing: spacing)

        // Calculate trailing view width
        let visibleTrailingViews = trailingViews.filter { !$0.isHidden }
        let trailingWidth = calculateViewsWidth(views: visibleTrailingViews, spacing: spacing)

        return leadingWidth + trailingWidth
    }

    private func calculateViewsWidth(views: [UIView], spacing: CGFloat) -> CGFloat {
        guard !views.isEmpty else { return 0 }

        let totalWidth = views.reduce(0) { $0 + $1.frame.width }
        let totalSpacing = CGFloat(max(0, views.count - 1)) * spacing
        return totalWidth + totalSpacing
    }

    // UI
    private var leadingViews: [UIView] = []
    private var trailingViews: [UIView] = []
    let textField = UITextField()
    private let separator = UIView()
    private let errorLabel = UILabel()

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
        errorLabel.font = .systemFont(ofSize: Layout.errorFontSize)

        separator.backgroundColor = UIColor(white: 0.9, alpha: 1)

        layer.masksToBounds = true

        addSubview(textField)
        addSubview(separator)
        addSubview(errorLabel)

        textField.borderStyle = .none
        textField.clearButtonMode = .never
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
        let patch = styleEngine.resolve(for: iState, vState.phase)

        let hPadding = patch.horizontalPadding ?? Layout.horizontalPadding
        let vSpacing = patch.verticalSpacing ?? Layout.verticalSpacing
        let accessorySpacing = patch.accessorySpacing ?? Layout.accessorySpacing
        let containerPadding = patch.containerPadding ?? Layout.containerPadding
        let textFieldHeight: CGFloat = ceil(textField.font!.lineHeight)

        // Position textField at top with container padding
        textField.frame = CGRect(x: 0, y: containerPadding, width: width, height: textFieldHeight)

        // Layout leading views (left side accessories)
        let visibleLeadingViews = leadingViews.filter { !$0.isHidden }
        var currentX: CGFloat = hPadding
        var lastLeadingView: UIView?

        for view in visibleLeadingViews {
            let viewWidth = view.frame.width
            let viewHeight = view.frame.height
            let centerY = textField.frame.midY

            view.frame = CGRect(
                x: currentX,
                y: centerY - viewHeight / 2,
                width: viewWidth,
                height: viewHeight
            )

            currentX += viewWidth + accessorySpacing
            lastLeadingView = view
        }

        // Layout trailing views (right side accessories)
        let visibleTrailingViews = trailingViews.filter { !$0.isHidden }
        currentX = width - hPadding
        var lastTrailingView: UIView?

        for view in visibleTrailingViews.reversed() {
            let viewWidth = view.frame.width
            let viewHeight = view.frame.height
            let centerY = textField.frame.midY

            currentX -= viewWidth
            view.frame = CGRect(
                x: currentX,
                y: centerY - viewHeight / 2,
                width: viewWidth,
                height: viewHeight
            )

            currentX -= accessorySpacing
            lastTrailingView = view
        }

        // Position textField between leading and trailing views
        var textFieldX: CGFloat = hPadding
        var textFieldWidth = width - 2 * hPadding

        if let lastLeading = lastLeadingView {
            textFieldX = lastLeading.frame.maxX + accessorySpacing
            textFieldWidth = width - textFieldX - hPadding
        }

        if let lastTrailing = lastTrailingView {
            textFieldWidth = lastTrailing.frame.minX - accessorySpacing - textFieldX
        }

        textField.frame = CGRect(
            x: textFieldX,
            y: containerPadding,
            width: max(0, textFieldWidth),
            height: textFieldHeight
        )

        // Position separator below textField
        let separatorY = textField.frame.maxY + containerPadding
        separator.frame = CGRect(
            x: 0,
            y: separatorY,
            width: width,
            height: Layout.separatorHeight
        )

        // Position error label if visible
        if !errorLabel.isHidden {
            errorLabel.frame = CGRect(
                x: 0,
                y: separator.frame.maxY + vSpacing,
                width: width,
                height: 0
            )
            errorLabel.sizeToFit()
            return errorLabel.frame.maxY
        } else {
            return separator.frame.maxY
        }
    }
}

// MARK: - State Management & Validation
extension ValidatedTextField {
    private func attachHandlers() {
        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
        textField.delegate = self
    }

    @objc private func editingDidBegin() {
        iState = .editing
        updateState()
    }

    @objc private func editingDidEnd() {
        iState = isEnabled ? .idle : .disabled
        didCommitOnce = true
        updateState()
        processValidation(triggeredByChange: false, committed: true)
    }

    private func setTextWithFormatting(_ newText: String) {
        let currentText = textField.text ?? ""
        let range = NSRange(location: 0, length: currentText.count)
        _ = textField(textField, shouldChangeCharactersIn: range, replacementString: newText)
    }

    private func shouldValidate(triggeredByChange: Bool, committed: Bool = false) -> Bool {
        switch strategy.trigger {
        case .onChange:
            return triggeredByChange
        case .onCommit:
            return committed
        case .afterCommitThenChange:
            return committed || (didCommitOnce && triggeredByChange)
        }
    }

    private func processValidation(triggeredByChange: Bool, committed: Bool = false) {
        if !shouldValidate(triggeredByChange: triggeredByChange, committed: committed) {
            return
        }

        let raw = textField.text ?? ""

        if let v = strategy.validator {
            let result = v.validate(raw)
            switch result {
            case .valid:
                vState = .valid
            case .invalid(let message):
                vState = .invalid(message: message)
            }
        } else {
            vState = .valid
        }
        updateState()
    }

    private func updateState() {
        render()
        broadcast()
    }

    private func broadcast() {
        accessories.forEach { $0.apply(interaction: iState, validation: vState) }

        let currentWidth = calculateVisibleAccessoryWidth()
        if currentWidth != previousAccessoryWidth {
            previousAccessoryWidth = currentWidth
            setNeedsLayout()
        }
    }

    private func render() {
        let patch = styleEngine.resolve(for: iState, vState.phase)
        UIView.animate(withDuration: 0.15) {
            // Apply style patch to self
            patch.apply(to: self)
            switch self.vState {
            case .invalid(let message):
                self.errorLabel.text = message
                self.errorLabel.isHidden = false
            default:
                self.errorLabel.isHidden = true
                self.errorLabel.text = nil
            }
        }
    }
}

// MARK: - Accessory Layout Handling
extension ValidatedTextField: AccessoryContainer {
    /// Called when accessory needs to notify container to relayout
    /// - Note: This method is called by AccessoryPlugin extension implementation
    public func invalidateAccessoryLayout() {
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func reloadAccessories() {
        leadingViews.forEach { $0.removeFromSuperview() }
        trailingViews.forEach { $0.removeFromSuperview() }
        leadingViews.removeAll()
        trailingViews.removeAll()

        if accessories.isEmpty {
            return
        }

        let proxy = TextProxy(
            get: { [weak self] in self?.textField.text ?? "" },
            set: { [weak self] newText in
                guard let self = self else { return }
                self.setTextWithFormatting(newText)
            },
            replace: { [weak self] transform in
                guard let self = self else { return }
                var current = self.textField.text ?? ""
                transform(&current)
                self.setTextWithFormatting(current)
            }
        )

        for plugin in accessories {
            plugin.bind(text: proxy)
            let view = plugin.view
            switch plugin.placement {
            case .leading:
                leadingViews.append(view)
                addSubview(view)
            case .trailing:
                trailingViews.append(view)
                addSubview(view)
            }
        }

        broadcast()
    }
}

// MARK: - UITextFieldDelegate
extension ValidatedTextField: UITextFieldDelegate {
    public func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if let formatter = strategy.formatter {
            let currentText = textField.text ?? ""
            guard let range = Range(range, in: currentText) else {
                return false
            }

            let newText = currentText.replacingCharacters(in: range, with: string)

            let change = TextChange(
                previousText: currentText,
                newText: newText,
                changeRange: range,
                replacementString: string,
                cursorPosition: range.lowerBound.utf16Offset(in: currentText) + string.count
            )

            let result = formatter.format(change: change)

            textField.text = result.formattedText

            if let newPosition = result.cursorPosition {
                let clampedPosition = max(0, min(newPosition, result.formattedText.count))
                if let newRange = textField.textRange(
                    from: textField.position(
                        from: textField.beginningOfDocument, offset: clampedPosition)!,
                    to: textField.position(
                        from: textField.beginningOfDocument, offset: clampedPosition)!
                ) {
                    textField.selectedTextRange = newRange
                }
            }

            processValidation(triggeredByChange: true)

            // Real-time update accessory (e.g. ClearButton), override editing change timing
            self.broadcast()

            return false
        }

        DispatchQueue.main.async {
            self.processValidation(triggeredByChange: true)
        }

        // Real-time update accessory (e.g. ClearButton), override editing change timing
        self.broadcast()

        return true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    public func textFieldDidChangeSelection(_ textField: UITextField) {
        switch self.cursorPosition {
        case .default:
            // Default to end, no need to set
            break
        case .end:
            if let endPostion = self.textField.position(
                from: self.textField.endOfDocument, offset: 0)
            {
                self.textField.selectedTextRange = self.textField.textRange(
                    from: endPostion, to: endPostion)
            }
        case .start:
            if let startPosition = self.textField.position(
                from: self.textField.beginningOfDocument, offset: 0)
            {
                self.textField.selectedTextRange = self.textField.textRange(
                    from: startPosition, to: startPosition)
            }
        }
    }
}

# ValidatedTextField

A powerful, customizable text field component for iOS with built-in validation, formatting, and comprehensive styling support.

## Features

- **Input Validation**: Built-in validator system with support for custom validation rules
- **Input Formatting**: Real-time text formatting with cursor position management
- **Accessory System**: Extensible accessory views (leading/trailing) for additional UI elements
- **Styling**: Comprehensive styling system with state-based theming
- **Pure UIKit**: Zero external dependencies - built entirely with UIKit
- **UIKit Integration**: Seamless integration with existing UIKit applications

## Requirements

- iOS 12.0+
- Swift 5.9+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/zhuolingzhao007/ValidatedTextField.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. Go to File > Add Packages...
2. Enter the package URL: `https://github.com/zhuolingzhao007/ValidatedTextField.git`
3. Select the version you want to use

## Usage

### Basic Usage

```swift
import ValidatedTextField

let textField = ValidatedTextField()

// Set placeholder
textField.placeholder = "Enter your email"

// Configure validation
textField.strategy = ValidationStrategy(
    validator: createValidator {
        // Email validation logic
        Validator { input in
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
            return emailPredicate.evaluate(with: input) ? .valid : .invalid(message: "Invalid email format")
        }
    }
)

// Add to your view
view.addSubview(textField)
```

### Validation State Observation

```swift
// Observe validation state changes
textField.onValidationChanged = { state in
    switch state {
    case .valid:
        print("Input is valid")
    case .invalid(let message):
        print("Validation error: \(message)")
    case .none:
        print("No validation applied")
    }
}
```

### Custom Styling

```swift
textField.configureStyle { builder in
    builder
        .textColor(.black)
        .placeholderColor(.gray)
        .cornerRadius(8)
        .borderWidth(1)

    builder.onInteraction(.editing) { patch in
        patch.borderColor = .blue
    }

    builder.onValidation(.invalid) { patch in
        patch.borderColor = .red
    }
}
```

## Architecture

### Core Components

- **ValidatedTextField**: Main UIView component
- **ValidationStrategy**: Combines formatting and validation logic
- **InputFormatter**: Handles text formatting and cursor positioning
- **InputValidator**: Protocol for validation logic
- **AccessoryPlugin**: Extensible accessory view system
- **StyleEngine**: State-based styling system

### Validation System

The validation system supports:
- Custom validation functions
- Builder pattern for combining validators
- Logical operators (AND, OR, NOT)
- Real-time and on-commit validation triggers

### Formatting System

- Real-time text formatting
- Cursor position management
- Support for complex formatting rules (phone numbers, credit cards, etc.)

## Dependencies

None - Pure UIKit implementation with zero external dependencies.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

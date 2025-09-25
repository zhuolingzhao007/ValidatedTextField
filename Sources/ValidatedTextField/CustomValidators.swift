// Custom Validators Extension
// Created for parameterized non-empty validation and copied validators

import Foundation

extension Validator {
  /// 参数化自定义非空验证：支持自定义消息和 trim 字符集
  /// - Parameters:
  ///   - message: 无效时的提示消息
  ///   - trimSet: 要去除的字符集（默认空白和换行）
  /// - Returns: Validator 实例
  public static func customNonEmpty(
    message: String, trimSet: CharacterSet = .whitespacesAndNewlines
  ) -> Validator {
    Validator { input in
      let trimmed = input.trimmingCharacters(in: trimSet)
      return trimmed.isEmpty ? .invalid(message: message) : .valid
    }
  }

  // 复制自 Validators.swift 的静态 let，支持快速使用
  public static let nonEmpty = Validator { input in
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? .invalid(message: "不能为空") : .valid
  }

  public static let phone = Validator { input in
    let digits = input.filter(\.isNumber)
    if digits.isEmpty {
      return .invalid(message: "请输入手机号")
    }
    // 使用正则表达式验证中国大陆手机号
    let regex = "^1[3-9]\\d{9}$"
    let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
    return predicate.evaluate(with: digits) ? .valid : .invalid(message: "请输入有效的手机号")
  }

  /// 验证码 validator: 非空 + 长度检查，支持参数化
  /// - Parameters:
  ///   - length: 验证码长度 (默认4)
  ///   - emptyMessage: 空提示 (默认 "验证码不能为空")
  /// - Returns: 组合 Validator
  public static func codeValidator(length: Int = 4, emptyMessage: String = "验证码不能为空") -> Validator {
    let lengthValidator = Validator { input in
      let digits = input.filter(\.isNumber)
      return digits.count == length ? .valid : .invalid(message: "验证码必须是\(length)位数字")
    }
    return customNonEmpty(message: emptyMessage) && lengthValidator
  }
}

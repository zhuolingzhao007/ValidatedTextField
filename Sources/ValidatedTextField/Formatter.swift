//
//  FormattingResult.swift
//  Pods
//
//  Created by zhuolingzhao on 9/14/25.
//


// MARK: - 格式化结果
public struct FormattingResult {
  public let formattedText: String
  public let cursorPosition: Int?  // 新的光标位置，nil表示不改变
  
  public init(formattedText: String, cursorPosition: Int? = nil) {
    self.formattedText = formattedText
    self.cursorPosition = cursorPosition
  }
}

// MARK: - 文本变化信息
public struct TextChange {
  public let previousText: String      // 变化前的文本
  public let newText: String          // 变化后的文本  
  public let changeRange: NSRange     // 变化范围
  public let replacementString: String // 替换的字符串
  public let cursorPosition: Int      // 当前光标位置
  
  public init(
    previousText: String,
    newText: String,
    changeRange: NSRange,
    replacementString: String,
    cursorPosition: Int
  ) {
    self.previousText = previousText
    self.newText = newText
    self.changeRange = changeRange
    self.replacementString = replacementString
    self.cursorPosition = cursorPosition
  }
  
  // 便利属性
  public var isInsertion: Bool { !replacementString.isEmpty }
  public var isDeletion: Bool { replacementString.isEmpty && changeRange.length > 0 }
  public var isReplacement: Bool { !replacementString.isEmpty && changeRange.length > 0 }
}

// MARK: - 格式化协议
public protocol InputFormatter {
  
  /// 统一格式化方法 - 处理文本变化
  func format(change: TextChange) -> FormattingResult
  
  // MARK: - 字符过滤
  /// 是否允许输入指定字符
  func shouldAllowCharacter(_ character: Character, at position: Int, in text: String) -> Bool
  
  /// 过滤原始文本，只保留允许的字符
  func filterRawText(_ text: String) -> String
  
  // MARK: - 长度限制  
  /// 最大原始字符长度（过滤后）
  var maxRawLength: Int? { get }
  
  /// 最大格式化后字符长度
  var maxFormattedLength: Int? { get }
  
  // MARK: - 格式验证
  /// 检查格式化后的文本是否有效
  func isValidFormat(_ formattedText: String) -> Bool
}

// MARK: - 默认实现
extension InputFormatter {
  
  // MARK: - 默认实现
  
  public func shouldAllowCharacter(_ character: Character, at position: Int, in text: String) -> Bool {
    return true // 默认允许所有字符
  }
  
  public func filterRawText(_ text: String) -> String {
    return text // 默认不过滤
  }
  
  public var maxRawLength: Int? { return nil }
  public var maxFormattedLength: Int? { return nil }
  
  public func isValidFormat(_ formattedText: String) -> Bool {
    return true // 默认认为都有效
  }
}


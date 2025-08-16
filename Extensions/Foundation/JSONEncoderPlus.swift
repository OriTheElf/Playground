//
//  JSONEncoderPlus.swift
//  KnowLED
//
//  Created by Choi on 2024/8/7.
//

import Foundation

extension JSONEncoder {
    
    /// 通用JSONEncoder | 不要修改属性, 只用于简单编解码. 其他情况需要使用单独的实例
    static let instance = JSONEncoder()
    
    static func encode<T>(_ value: T) throws -> Data where T : Encodable {
        instance.encode(value)
    }
    
    /// 时间以毫秒解析的Encoder
    static let millisecondsDateEncodingEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return encoder
    }()
}

//
//  JSONDecoderPlus.swift
//  KnowLED
//
//  Created by Choi on 2024/8/7.
//

import Foundation

extension JSONDecoder {
    
    /// 通用JSONDecoder | 不要修改属性, 只用于简单编解码. 其他情况需要使用单独的实例
    static let instance = JSONDecoder()
    
    static func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        try instance.decode(type, from: data)
    }
    
    /// 时间以毫秒解析的Decoder
    static let millisecondsDateDecodingDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()
}

//MARK: -- 可变参数的解码
extension KeyedDecodingContainer {
    
    /// 可变参数的解码，用于不同模型不同属性的解码
    /// - Parameters:
    ///   - type: 解码的对象或者属性
    ///   - keys: 解码的Keys
    /// - Returns: 解码后的数据，如果解码失败则数据为空
    func decode<T: Decodable>(_ type: T.Type, forKeys keys: Key...) -> T? {
        for key in keys {
            guard let value = try? decode(T.self, forKey: key) else { continue }
            return value
        }
        return nil
    }
}

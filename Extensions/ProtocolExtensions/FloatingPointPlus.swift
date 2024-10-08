//
//  FloatingPointPlus.swift
//  KnowLED
//
//  Created by Choi on 2024/9/5.
//

import Foundation

extension FloatingPoint {
    
    /// 实时创建的百分比范围, 尽量避免直接使用. 在常用的类型扩展里储存一份静态常量
    static var hotPercentRange: ClosedRange<Self> { 0...1 }
    
    /// 切分成整数和小数两个部分
    var modf: (integerPart: Self, fractionalPart: Self) {
        Darwin.modf(self)
        /*
        /// 以下为之前的逻辑 | 具体类型Double/Float分别使用modf/modff方法, 由于需要分别传入具体类型
        /// 不如上面的方法简洁, 以下示例只做存档
        /// 创建Double类型的指针
        let pointer = UnsafeMutablePointer<Double>.allocate(capacity: 1)
        defer {
            pointer.deallocate()
        }
        /// 执行整数小数分离 | 把整数部分存入指针
        let fractionalPart = Darwin.modf(self, pointer)
        return (pointer.pointee, fractionalPart)
        */
    }
    
    /// 按照指定精度和进位规则进位
    /// - Parameters:
    ///   - roundingIncrement: 进位精度
    ///   - rule: 进位规则
    /// - Returns: 进位后的结果
    /// 这里的形参命名借用了NumberFormatter的同名属性, 具体作用在NumberFormatterPlus中的reset()方法中的属性注释中有详细说明
    func rounded(_ roundingIncrement: Self, rule: FloatingPointRoundingRule) -> Self {
        roundingIncrement * (self / roundingIncrement).rounded(rule)
    }
    
    mutating func round(_ roundingIncrement: Self, rule: FloatingPointRoundingRule) {
        self = rounded(roundingIncrement, rule: rule)
    }
}

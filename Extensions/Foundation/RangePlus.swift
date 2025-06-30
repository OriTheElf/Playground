//
//  RangePlus.swift
//
//  Created by Choi on 2022/12/6.
//

import Foundation

extension Range {
    
    /// 判断左面的范围是否包含右面
    /// 注: Swift顶层方法有个一模一样的全局方法, 只对比二者是否相等
    /// func ~= <T>(a: T, b: T) -> Bool where T : Equatable
    /// 这里为对此运算符方法的重载, 切记不要轻易删除此方法, 除非将所有相关位置都替换成显示调用.contains方法
    static func ~=(lhs: Self, rhs: Self) -> Bool {
        lhs.contains(rhs)
    }
}

extension Range where Bound: Strideable, Bound.Stride: SignedInteger {
    
    /// 返回最后一个index | Range非空时有效(如果isEmpty还调用index(before:)方法程序会崩溃)
    var maybeLastIndex: Index? {
        isEmpty ? nil : index(before: endIndex)
    }
}

extension Range where Bound: BinaryInteger, Bound.Stride: SignedInteger {
    
    public static func * (lhs: Self, rhs: Double) -> Bound? {
        lhs[multiply: rhs]
    }
    
    /// 计算一个半开范围 × 进度 -> Bound?类型
    /// 如: 数组索引 0..<100 * 0.99 -> 99, 0..<100 * 1.0 -> 99, upperbound不可达
    subscript (multiply progress: Double, digits digit: Int? = nil, roundingRule rule: FloatingPointRoundingRule? = nil) -> Bound? {
        /// 最终结果
        guard var result = doubleRange * progress else { return nil }
        let power = digit.map { digit in
            pow(10.0, digit.double)
        }
        /// 将结果放大
        if let power {
            result *= power
        }
        /// 进位之后
        if let rule {
            result.round(rule)
        }
        /// 按精确到小数位缩小
        if let power {
            result /= power
        }
        /// 最后
        guard let closedRange else { return nil }
        /// 按照闭合范围约束结果
        return closedRange << Bound(result)
    }
    
    var doubleRange: Range<Double> {
        lowerBound.double..<upperBound.double
    }
    
    /// 返回一个闭合的范围
    /// 如: 0..<10 -> 0...9 | 如果.isEmpty, 例如: 0..<0, 则返回nil
    /// 用于数组索引范围转换成一个有效的闭合范围
    /// [1,2,3].indexRange -> 0..<3 -> 0...2; 如果数组为空, 则索引范围0..<0 -> nil
    var closedRange: ClosedRange<Bound>? {
        isEmpty ? nil : ClosedRange(self)
    }
    
    /// 循环Index | 如: 利用下标循环访问数组的元素
    /// 如: (0..<3)[cycledIndex: 4] == 0
    /// 如: (8..<11)[cycledIndex: -1] == 10
    subscript (cycledIndex cycledIndex: Bound) -> Bound? {
        /// 序列为空的情况返回nil | 如: 0..<0
        if isEmpty { return nil }
        /// 大于等于上限 | 返回最小Index
        if cycledIndex >= upperBound {
            return lowerBound
        }
        /// 小于下限 | 返回最大Index
        else if cycledIndex < lowerBound {
            return index(before: endIndex)
        } else {
            return cycledIndex
        }
    }
}

extension Range where Bound == Int {
    
    /// 循环Index | 对输入的Index求余使得用余数配合上下限返回有效的索引值
    /// 如: (0..<3)[modIndex: 4] == 1
    /// 如: (8..<11)[modIndex: 3] == 9
    subscript (modIndex modIndex: Bound) -> Bound? {
        /// 序列为空的情况返回nil | 如: 0..<0
        if isEmpty { return nil }
        /// 单个元素情况直接返回lowerBound
        if count == 1 { return lowerBound }
        /// 大于等于上限
        if modIndex >= upperBound {
            let distance = modIndex - upperBound
            return lowerBound + distance % count
        }
        /// 小于下限
        else if modIndex < lowerBound {
            let distance = modIndex - lowerBound
            let mod = distance % count
            return mod == 0 ? lowerBound : index(upperBound, offsetBy: mod)
        } else {
            return modIndex
        }
    }
}

extension Range where Bound == Double {
    
    /// 计算范围 × 进度的结果.
    /// 如: 0..<100.0 * 0.99 -> 99
    /// 如: 0..<100.0 * 1.00 -> 100
    /// 注: Double类型的Bound Range × 进度似乎无太大意义(因为upperbound永远不可达), 但是在Bound为BinaryInteger的Range中计算进度却十分有用
    public static func * (lhs: Self, rhs: Double) -> Double? {
        lhs.isEmpty ? nil : lhs.lowerBound + (lhs.upperBound - lhs.lowerBound) * (Double.percentRange << rhs)
    }
}

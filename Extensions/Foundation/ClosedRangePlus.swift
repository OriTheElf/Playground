//
//  ClosedRangePlus.swift
//  KnowLED
//
//  Created by Choi on 2023/12/28.
//

import Foundation

extension ClosedRange: @retroactive ExpressibleByIntegerLiteral where Bound == Int {
    public typealias IntegerLiteralType = Bound
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(uncheckedBounds: (lower: value, upper: value))
    }
}

extension ClosedRange where Bound: Codable {
    
    /// 转换为JSON二进制
    var jsonData: Data {
        get throws {
            try JSONEncoder.encode(self)
        }
    }
}

extension ClosedRange where Bound == CGFloat {
    static let percentRange = CGFloat.percentRange
}

extension ClosedRange where Bound == Double {
    static let percentRange = Double.percentRange
}

extension ClosedRange where Bound == Int {
    
    /// 计算一个Range在另一个Range中的索引范围
    /// - Parameter another: 要计算的Range
    /// - Returns: 索引范围
    func indexRange(of another: ClosedRange<Bound>) -> Range<Int>? {
        guard self.contains(another) else { return nil }
        let startIndex = lowerBound.distance(to: another.lowerBound)
        let endIndex = lowerBound.distance(to: another.upperBound) + 1
        guard startIndex < endIndex else { return nil }
        return startIndex..<endIndex
    }
    
    /// 返回保留前几个数的Range. 例如: 1...5 保留前三个数 -> 1...3 | 如果截取失败则返回原值
    func keep(first: Int) -> Self {
        guard let upperBound = index(startIndex, offsetBy: first - 1, limitedBy: lastIndex) else { return self }
        return lowerBound...self[upperBound]
    }
    
    /// 返回保留后几个数的Range. 例如: 1...5 保留后三个数 -> 3...5 | 如果截取失败则返回原值
    func keep(last: Int) -> Self {
        guard let lowerBound = index(endIndex, offsetBy: -last, limitedBy: startIndex) else { return self }
        return self[lowerBound]...upperBound
    }
    
    /// 将范围映射成索引
    var indexRange: ClosedRange<Int> {
        lowerBound.index...upperBound.index
    }
    
    var numberRange: ClosedRange<Int> {
        lowerBound.number...upperBound.number
    }
}

extension ClosedRange {
    
    public init(lowerBound: Bound, upperBound: Bound) throws {
        if upperBound < lowerBound {
            throw "UpperBound is less than lowerBound."
        }
        self.init(uncheckedBounds: (lowerBound, upperBound))
    }
    
    /// 求与另一个范围的交集
    /// - Parameter other: 传入的闭合范围
    /// - Returns: 两个范围的交集
    public func intersection(_ other: Self) -> Self? {
        let newLowerBound = Swift.max(lowerBound, other.lowerBound)
        let newUpperBound = Swift.min(upperBound, other.upperBound)
        guard newLowerBound <= newUpperBound else { return nil }
        return newLowerBound...newUpperBound
    }
    
    /// 根据传入值计算进度
    /// - Parameter value: 传入值
    /// - Returns: 进度百分比<0~1.0>
    public func progress(for value: Bound) -> Double where Bound: BinaryInteger {
        doubleRange.progress(for: value.double)
    }
    
    /// 根据传入值计算进度
    /// - Parameter value: 传入值
    /// - Returns: 进度百分比<0~1.0>
    public func progress(for value: Bound) -> Bound where Bound: BinaryFloatingPoint {
        do throws(RangeBoundError) {
            /// Range宽度
            let rangeWidth = width
            /// 除数不能为零
            guard rangeWidth != 0 else {
                /// 上下边界相等 | 大于等于上限则返回1.0
                return value >= upperBound ? 1.0 : 0.0
            }
            /// 检查范围
            let constrainedValue = try constrainedResult(value).get()
            /// 计算进度
            return (constrainedValue - lowerBound) / rangeWidth
        } catch {
            switch error {
            case .tooLow:
                return 0.0
            case .tooHigh:
                return 1.0
            }
        }
    }
    
    /// 返回限制后的值
    /// - Parameters:
    ///   - lhs: ClosedRange
    ///   - rhs: 值
    /// - Returns: 限制在范围内的值
    static func <<(lhs: Self, rhs: Bound) -> Bound {
        lhs.constrainedValue(rhs)
    }
    
    /// 将传入的值限制在范围内部 | 过大或过小则取相应的极值
    /// - Parameter value: 需要限制的传入值
    /// - Returns: 限制过后的值
    func constrainedValue(_ value: Bound) -> Bound {
        do throws(RangeBoundError) {
            return try constrainedResult(value).get()
        } catch {
            switch error {
            case .tooLow:
                return lowerBound
            case .tooHigh:
                return upperBound
            }
        }
    }
    
    /// 将传入值限制在范围内
    /// - Parameter value: 需要限制的值
    /// - Returns: Result包含有效值或错误
    func constrainedResult(_ value: Bound) -> Result<Bound, RangeBoundError> {
        if value < lowerBound {
            return .failure(.tooLow)
        } else if value > upperBound {
            return .failure(.tooHigh)
        } else {
            return .success(value)
        }
    }
}

extension ClosedRange where Bound: BinaryInteger {
    
    /// 计算ClosedRange × 进度的结果 | 如果结果的小数位>=fractionalPartThreshold直接进一位
    subscript (multiply progress: Double, fractionalPartThreshold: Double = 0.999) -> Bound {
        let doubleBound = (doubleRange * progress).rectified(fractionalPartThreshold)
        return Bound(doubleBound)
    }
    
    /// 转换成CGFloat范围
    var cgFloatRange: ClosedRange<CGFloat> {
        lowerBound.cgFloat...upperBound.cgFloat
    }
    
    /// 转换成Double范围
    var doubleRange: ClosedRange<Double> {
        lowerBound.double...upperBound.double
    }
    
    /// 转换成Int范围
    var intRange: ClosedRange<Int> {
        lowerBound.int...upperBound.int
    }
    
    public static func * (lhs: Double, rhs: Self) -> Bound { rhs * lhs }
    public static func * (lhs: Self, rhs: Double) -> Bound {
        Bound(lhs.doubleRange * rhs)
    }
}

extension ClosedRange where Bound: BinaryFloatingPoint {
    public static func * (lhs: Bound, rhs: Self) -> Bound { rhs * lhs }
    public static func * (lhs: Self, percentage: Bound) -> Bound {
        lhs.lowerBound + lhs.width * (Bound.hotPercentRange << percentage)
    }
}

extension ClosedRange where Bound == Decimal {
    public static func * (lhs: Bound, rhs: Self) -> Bound { rhs * lhs }
    public static func * (lhs: Self, percentage: Bound) -> Bound {
        lhs.lowerBound + lhs.width * (Bound.percentRange << percentage)
    }
}

extension ClosedRange where Bound: Numeric {
    
    /// 上下边界分别偏移一定的距离
    /// - Parameter distance: 偏移距离
    /// - Returns: 新的范围对象
    public func offseted(by distance: Bound) -> ClosedRange<Bound> {
        (lowerBound + distance)...(upperBound + distance)
    }
    
    public mutating func offset(by distance: Bound) {
        self = (lowerBound + distance)...(upperBound + distance)
    }
    
    /// 放大指定倍数 | 两个边界分别乘以倍数
    /// - Parameter multiple: 倍数
    /// - Returns: 放大后的闭合区间
    public func scaled(by multiple: Bound) -> Self {
        (lowerBound * multiple)...(upperBound * multiple)
    }
    
    /// 放大指定倍数 | 两个边界分别乘以倍数
    /// - Parameter multiple: 倍数
    public mutating func scale(by multiple: Bound) {
        self = self.scaled(by: multiple)
    }
}

extension ClosedRange where Bound == Double {
    
    /// 计算ClosedRange × 进度的结果, 保留相应的小数位, 并按指定规则进位
    subscript (multiply progress: Double, fractionDigits fractionDigits: Int? = nil, roundingRule rule: FloatingPointRoundingRule? = nil) -> Bound {
        /// 最终结果
        var result = self * progress
        /// 10的n次幂
        let power = fractionDigits.map { digits in
            pow(10.0, digits.double)
        }
        /// 乘以10的n次幂
        if let power {
            result *= power
        }
        /// 进位之后
        if let rule {
            result.round(rule)
        }
        /// 除以10的n次幂
        if let power {
            result /= power
        }
        return result
    }
}

extension ClosedRange where Bound: Equatable {
    
    /// 例如像1...1这样的闭合范围
    var isNarrow: Bool {
        upperBound == lowerBound
    }
}

extension ClosedRange where Bound: AdditiveArithmetic {
    
    /// 返回ClosedRange的宽度(上限-下限)
    var width: Bound {
        upperBound - lowerBound
    }
}

extension ClosedRange: @retroactive Comparable where Bound: Comparable {
    public static func < (lhs: ClosedRange<Bound>, rhs: ClosedRange<Bound>) -> Bool {
        lhs.upperBound < rhs.lowerBound
    }
}

extension ClosedRange where Bound: Strideable, Bound.Stride: SignedInteger {
    
    /// Bound类型的最后一个Index
    /// 例: ClosedRange<Int>(0..<10).lastBoundIndex == Int(9)
    /// 例: ClosedRange<UInt8>(0..<10).lastBoundIndex == UInt8(9)
    public var lastBoundIndex: Bound {
        if case .inRange(let boundIndex) = lastIndex {
            return boundIndex
        } else {
            fatalError("NOT SUPPOSE TO HAPPEN.")
        }
    }
    
    /// 获取指定位置的元素
    public func itemAt(_ offset: Int) -> Bound? {
        index(startIndex, offsetBy: offset, limitedBy: lastIndex).map { index in
            self[index]
        }
    }
}

extension ClosedRange {
    
    /// 取两个范围的交集
    static func ^ (lhs: Self, rhs: Self) -> Self? {
        lhs.intersection(rhs)
    }
}

/// 同ClosedRange.SubSequence类型
extension Slice where Base == ClosedRange<Int> {
    
    /// 方便将Algorithms模块中
    /// chunks(ofCount count: Int) -> ChunksOfCountCollection<Self>
    /// 生成的片段转换回闭合区间
    var closedRange: Base {
        first.unsafelyUnwrapped...last.unsafelyUnwrapped
    }
}

// MARK: - 其他
enum RangeBoundError: Error {
    case tooLow
    case tooHigh
}

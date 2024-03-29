//
//  ArrayPlus.swift
//
//  Created by Choi on 2022/10/21.
//

import Foundation

extension Array {
    
    init(@ArrayBuilder<Element> _ itemsBuilder: () -> Self) {
        self.init(itemsBuilder())
    }
    
    public mutating func refill(@ArrayBuilder<Element> _ builder: () -> [Element]) {
        refill(builder())
    }
    
    public mutating func refill(_ newElements: Element...) {
        refill(newElements)
    }
    
    public mutating func refill(_ newElements: [Element]) {
        removeAll()
        append(contentsOf: newElements)
    }
    
    public mutating func append(@ArrayBuilder<Element> _ builder: () -> [Element]) {
        let elements = builder()
        append(contentsOf: elements)
    }
    
    /// 下标方式获取指定位置的元素
    subscript (itemAt index: Index) -> Element? {
        itemAt(index)
    }
    
    /// 循环访问数组元素 | 如: 利用下标循环访问数组的元素
    subscript (cycledElement inputIndex: Self.Index) -> Element? {
        guard let safeIndex = indices[safeIndex: inputIndex] else { return nil }
        return self[safeIndex]
    }
    
    /// 获取指定位置的元素
    /// - Parameter index: 元素位置
    /// - Returns: 如果下标合规则返回相应元素
    public func itemAt(_ index: Index) -> Element? {
        guard (startIndex..<endIndex) ~= index else { return nil }
        return self[index]
    }
    
    /// 安全移除指定位置的元素
    /// - Parameter index: 元素位置
    /// - Returns: 如果存在,则返回被移除的元素
    public mutating func safeRemove(at index: Int) -> Element? {
        guard itemAt(index).isValid else { return nil }
        return remove(at: index)
    }
    
    public init(generating elementGenerator: (Int) -> Element, count: Int) {
        self = (0..<count).map(elementGenerator)
    }
    public init(generating elementGenerator: () -> Element, count: Int) {
        self = (0..<count).map { _ in
            elementGenerator()
        }
    }
}

// MARK: - Equatable Array
extension Array where Element: Equatable {
    
    @discardableResult
    /// 替换指定元素
    /// - Parameter newElement: 新元素
    /// - Returns: 是否替换成功
    public mutating func replace(
        with newElement: Element,
        if prediction: (_ old: Element, _ new: Element) -> Bool = { $0 == $1 }
    ) -> Bool {
        let index = firstIndex { oldElement in
            prediction(oldElement, newElement)
        }
        if let index {
            let range = index..<index + 1
            let updated = [newElement]
            replaceSubrange(range, with: updated)
            return true
        } else {
            append(newElement)
            return false
        }
    }
    
    @discardableResult
    /// 移除指定元素
    /// - Parameter element: 要移除的元素
    /// - Returns: 更新后的数组
    public mutating func remove(_ element: Element) -> Array {
        if let foundIndex = firstIndex(of: element) {
            remove(at: foundIndex)
        }
        return self
    }
}

// MARK: - Hashable Array
extension Array where Element : Hashable {
    
    mutating func appendUnique<S>(contentsOf newElements: S) where Element == S.Element, S : Sequence {
        newElements.forEach { element in
            appendUnique(element)
        }
    }
    
    /// 添加唯一的元素
    /// - Parameter newElement: 遵循Hashable的元素
    mutating func appendUnique(_ newElement: Element) {
        let isNotUnique = contains { element in
            element.hashValue == newElement.hashValue
        }
        guard !isNotUnique else { return }
        append(newElement)
    }
    
    /// 合并唯一的元素 | 可用于reduce
    /// - Parameters:
    ///   - lhs: 数组
    ///   - rhs: 要添加的元素
    /// - Returns: 结果数组
    static func +> (lhs: Self, rhs: Element) -> Self {
        var result = lhs
        result.appendUnique(rhs)
        return result
    }
    
    /// 合并数组
    /// - Parameters:
    ///   - lhs: 原数组
    ///   - rhs: 新数组
    /// - Returns: 合并唯一元素的数组
    static func +> (lhs: Self, rhs: Self) -> Self {
        rhs.reduce(lhs, +>)
    }
}

extension Array where Element: Numeric {
    
    /// 向量 * 矩阵
    static func * (vector: [Element], matrix: [[Element]]) -> [Element] {
        /// 确保向量数组和矩阵个数匹配
        guard vector.count == matrix.count else { return .empty }
        /// 内部的一维数组个数也必须匹配
        let innerArrayCountMatch = matrix.allSatisfy { array in
            array.count == vector.count
        }
        guard innerArrayCountMatch else { return .empty }
        var result: [Element] = []
        for row in 0..<vector.count {
            var resultElement: Element?
            for col in 0..<matrix.count {
                /// 乘积
                let product = matrix[col][row] * vector[col]
                /// 累加
                if let temResult = resultElement {
                    resultElement = temResult + product
                } else {
                    /// 赋初值
                    resultElement = product
                }
            }
            if let resultElement {
                result.append(resultElement)
            }
        }
        return result
    }
}

// MARK: - ArraySlice
extension ArraySlice {
    
    /// 转换为Array
    var array: Array<Element> {
        Array(self)
    }
}

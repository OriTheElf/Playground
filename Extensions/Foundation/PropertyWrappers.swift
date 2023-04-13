//
//  PropertyWrappers.swift
//  ExtensionDemo
//
//  Created by Choi on 2021/7/9.
//  Copyright © 2021 Choi. All rights reserved.
//

import Foundation

/// 源源不断的将新赋的有效值储存在内部的数组内, 自身返回最新值.
/// 用$语法取projectedValue使用
/// 配合Configurator的keyPath dynamicMemberLookup赋值效果更加
@propertyWrapper
struct ValueStorage<T> {
    
    var projectedValue: [T] = []
    
    var wrappedValue: T {
        get { _wrappedValue }
        set { _wrappedValue = newValue
            projectedValue.append(newValue)
        }
    }
    
    private var _wrappedValue: T
    
    init(wrappedValue: T) {
        _wrappedValue = wrappedValue
        projectedValue.append(wrappedValue)
    }
}

/// ValueStorage的Optional版本
@propertyWrapper
struct OptionalValueStorage<T> {
    
    var projectedValue: [T] = []
    
    var wrappedValue: T? {
        get { _wrappedValue }
        set { _wrappedValue = newValue
            guard let newValue else { return }
            projectedValue.append(newValue)
        }
    }
    
    private var _wrappedValue: T?
    
    init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }
}

/// 让值在某个范围内循环
@propertyWrapper
struct CycledValue<T: Comparable> {
    
    var wrappedValue: T {
        get { innerValue }
        set {
            if newValue > range.upperBound {
                innerValue = range.lowerBound
            } else if newValue < range.lowerBound {
                innerValue = range.upperBound
            } else {
                innerValue = newValue
            }
        }
    }
    private var innerValue: T
    private let range: ClosedRange<T>
    init(wrappedValue: T, range: ClosedRange<T>) {
        self.innerValue = wrappedValue
        self.range = range
    }
}

@propertyWrapper
struct Cached<T: Codable> {
    
    private lazy var jsonEncoder = JSONEncoder()
    private lazy var jsonDecoder = JSONDecoder()
    
    var wrappedValue: T? {
        mutating get {
            do {
                guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
                let value = try jsonDecoder.decode(T.self, from: data)
                return value
            } catch {
                return nil
            }
        }
        set {
            guard let validValue = newValue else { return }
            do {
                let data = try jsonEncoder.encode(validValue)
                UserDefaults.standard.set(data, forKey: key)
            } catch {
                dprint("Cache failed! - \(error)")
            }
        }
    }
    let key: String
    init(wrappedValue: T? = nil, key: String) {
        self.key = key
    }
}

@propertyWrapper
final class EditDetectable<E> where E: Equatable {
	
	var projectedValue: EditDetectable<E> {
		self
	}
	private var value: E?
	var wrappedValue: E? {
		get { value }
		set {
			value = newValue
			
			/// 根据命中条件决定是否继续执行 '命中' 方法
			if requirements.contains(.valid), newValue == .none { return }
			if let string = newValue as? String,
			   requirements.contains(.validString),
			   string.isEmptyString { return }
			hit(newValue)
		}
	}
	var needsUpdate: Bool {
		if hitCache.isEmpty { // 未命中
			return false
		} else { // 至少命中1次
			guard hitCache.count > 1 else {
				// 只命中了1次
				if requirements.contains(.ignoreInitialValue) {
					return false
				}
				return true
			}
			// 命中了2次以上
			// 校验当前值是否满足指定条件
			var isValid: Bool {
				guard requirements.contains(.valid) else { return true }
				return wrappedValue != .none
			}
			var isNotEmptyString: Bool {
				guard requirements.contains(.validString) else { return true }
				guard let string = wrappedValue as? String else { return false }
				return !string.isEmptyString
			}
			return isValid && isNotEmptyString && hitCache.first != hitCache.last
		}
	}
	
	private var lock = NSLock()
	private var hitCache: [E?] = []
	private func hit(_ value: E?) {
		lock.lock()
		if hitCache.count == 2 {
			hitCache.removeLast()
		}
		hitCache.append(value)
		lock.unlock()
	}
	
	private let requirements: ValueRequirement
	init(wrappedValue: E?, requirements: ValueRequirement = [.valid]) {
		self.requirements = requirements
		self.wrappedValue = wrappedValue
	}
}

struct ValueRequirement: OptionSet {
	let rawValue: Int
	static let valid              = ValueRequirement(rawValue: 1 << 0)
	static let validString        = ValueRequirement(rawValue: 1 << 1)
	static let ignoreInitialValue = ValueRequirement(rawValue: 1 << 2)
}


@propertyWrapper // 忽略Optional.none
class ValidValueOnly<T> where T: Equatable {
	private var value: T?
	init(wrappedValue: T?) {
		self.value = wrappedValue
	}
	var wrappedValue: T? {
		get { value }
		set {
			guard let validValue = newValue else {
				return // 直接忽略空值
			}
			value = validValue
		}
	}
}

@propertyWrapper // 忽略空字符串
final class IgnoreEmptyString: ValidValueOnly<String> {
	override var wrappedValue: String? {
		get { super.wrappedValue }
		set { super.wrappedValue = newValue.validStringOrNone }
	}
}

@propertyWrapper
/// 转瞬即逝的变量 | 用于开销较大的变量, 如:NumberFormatter,DateFormatter等
/// 经过指定的时间后自动销毁
final class Transient<T> {
    typealias ValueBuilder = () -> T
    
    /// 存储对象
    private var value: T?
    /// 对象构造方法
    private var valueBuilder: ValueBuilder?
    /// 最大取用次数
    private var maxTakeTime: UInt = .max {
        didSet {
            /// 如果取用次数归零
            if maxTakeTime == 0 {
                /// 将值置为空
                value = nil
                /// 销毁定时器
                timer.invalidate()
            }
        }
    }
    
    private let interval: DispatchTimeInterval
    private lazy var timer = GCDTimer.scheduledTimer(queue: .global(qos: .utility)) {
        [weak self] _ in self?.value = .none
    }
    
    init(wrappedValue: T? = nil, venishAfter interval: DispatchTimeInterval = 1.0) {
        self.value = wrappedValue
        self.interval = interval
        /// 如果初始化就有初值,则立即执行
        self.countDown()
    }
    
    /// 取用指定次数之后销毁
    /// - Parameters:
    ///   - maxTakeTime: 最大取用次数
    convenience init(wrappedValue: T? = nil, maxTakeTime: UInt = .max) {
        self.init(wrappedValue: wrappedValue, venishAfter: .seconds(.max))
        self.maxTakeTime = maxTakeTime
    }
    
    /// 超时后自动销毁 | 再次访问时重新创建
    /// - Parameters:
    ///   - wrappedValue: 值构造方法
    ///   - interval: 存活时间
    convenience init(wrappedValue: @escaping ValueBuilder, venishAfter interval: DispatchTimeInterval) {
        self.init(venishAfter: interval)
        self.valueBuilder = wrappedValue
    }
    
    private func countDown() {
        /// 只有值有效的时候才计时
        guard value.isValid else { return }
        timer.fire(.now() + interval)
    }
    
    var wrappedValue: T? {
        get {
            defer {
                countDown()
            }
            defer {
                if maxTakeTime > 0 {
                    /// 取用次数-1
                    maxTakeTime -= 1
                }
            }
            if let value {
                return value
            } else if let valueBuilder {
                let newValue = valueBuilder()
                value = newValue
                return newValue
            } else {
                return nil
            }
        }
        set {
            defer {
                countDown()
            }
            value = newValue
        }
    }
    
    deinit {
        timer.invalidate()
    }
}

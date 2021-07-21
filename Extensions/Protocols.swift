//
//  Protocols.swift
//
//  Created by Choi on 2020/9/6.
//  Copyright © 2020年 All rights reserved.
//

import UIKit

// MARK: - __________ Storyboarded __________
protocol Storyboarded {
	static var storyboardName: String { get }
	static func instantiate() -> Self
}
extension Storyboarded where Self: UIViewController {
	static var storyboardName: String { "Main" }
	static func instantiate() -> Self {
		let id = String(describing: self)
		let storyboard = UIStoryboard(name: storyboardName, bundle: .main)
		return storyboard.instantiateViewController(withIdentifier: id) as! Self
	}
}
extension UIViewController: Storyboarded {
}

// MARK: - __________ Configurable __________
protocol SimpleInitializer {
	init()
}
protocol Configurable {
	@discardableResult
	mutating func configure(_ configurator: (inout Self) -> Void) -> Self
}
typealias SimpleConfigurable = SimpleInitializer & Configurable
extension Configurable {
	@discardableResult
	mutating func configure(_ configurator: (inout Self) -> Void) -> Self {
		configurator(&self)
		return self
	}
}
protocol InstanceFactory {
	static func new(_ configurator: (inout Self) -> Void) -> Self
}
extension InstanceFactory where Self: SimpleConfigurable {
	static func new(_ configurator: (inout Self) -> Void) -> Self {
		var retval = Self()
		return retval.configure(configurator)
	}
}

protocol ClassConfigurable: AnyObject {}
extension ClassConfigurable {
	@discardableResult
	func configure(_ configurator: (Self) -> Void) -> Self {
		configurator(self)
		return self
	}
}
typealias SimpleClassConfigurable = SimpleInitializer & ClassConfigurable
protocol ClassNewInstanceConfigurable: SimpleClassConfigurable {}
extension ClassNewInstanceConfigurable {
	static func new(_ configurator: (Self) -> Void) -> Self {
		let retval = Self()
		return retval.configure(configurator)
	}
}

extension NSObject: ClassNewInstanceConfigurable {}

// MARK: - __________ Transformable Protocol __________
/// 转换自身为另一种类型
/// - Parameter transformer: 具体转换的实现过程
/// - Returns: 返回转换之后的实例
protocol Transformable {
	associatedtype E
	func transform<T>(_ transformer: (E) -> T) -> T
}

extension Transformable {
	func transform<T>(_ transformer: (Self) -> T) -> T {
		transformer(self)
	}
}

extension NSObject: Transformable {}
extension Set: Transformable {}
extension Array: Transformable {}
extension Dictionary: Transformable {}
extension DateComponents: Transformable {}
extension Calendar: Transformable {}

// MARK: - __________ Add Selector for UIControl Events Using a Closure __________
protocol Actionable {
    associatedtype T = Self
    func addAction(for controlEvents: UIControl.Event, _ action: ((T) -> Void)?)
}

private class ClosureSleeve<T> {
    let closure: ((T) -> Void)?
    let sender: T

    init (sender: T, _ closure: ((T) -> Void)?) {
        self.closure = closure
        self.sender = sender
    }

    @objc func invoke() {
        closure?(sender)
    }
}

extension Actionable where Self: UIControl {
	func addAction(for events: UIControl.Event = .touchUpInside, _ action: ((Self) -> Void)?) {
        let previousSleeve = objc_getAssociatedObject(self, String(events.rawValue))
        objc_removeAssociatedObjects(previousSleeve as Any)
        removeTarget(previousSleeve, action: nil, for: events)

        let sleeve = ClosureSleeve(sender: self, action)
        addTarget(sleeve, action: #selector(ClosureSleeve<Self>.invoke), for: events)
        objc_setAssociatedObject(self, String(events.rawValue), sleeve, .OBJC_ASSOCIATION_RETAIN)
    }
}
extension UIControl: Actionable {}

protocol SizeExtendable {
	
	/// 垂直方向扩展
	var vertical: CGFloat { get }
	
	/// 水平方向扩展
	var horizontal: CGFloat { get }
}


public protocol ReusableView: AnyObject {
	static var reuseIdentifier: String { get }
}
extension ReusableView {
	public static var reuseIdentifier: String {
		String(describing: self)
	}
}

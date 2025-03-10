//
//  UILayoutConstraint.swift
//  KnowLED
//
//  Created by Choi on 2023/8/15.
//

import UIKit

public struct UILayoutConstraint {
    let constant: Double
    let priority: UILayoutPriority
    init(constant: Double, priority: UILayoutPriority) {
        self.constant = constant
        self.priority = priority
    }
}

extension CGFloat {
    var constraint: UILayoutConstraint {
        constraint(priority: .required)
    }
    func constraint(priority: UILayoutPriority) -> UILayoutConstraint {
        UILayoutConstraint(constant: self, priority: priority)
    }
}

extension Double {
    var constraint: UILayoutConstraint {
        constraint(priority: .required)
    }
    func constraint(priority: UILayoutPriority) -> UILayoutConstraint {
        UILayoutConstraint(constant: self, priority: priority)
    }
}

extension Int {
    var constraint: UILayoutConstraint {
        constraint(priority: .required)
    }
    func constraint(priority: UILayoutPriority) -> UILayoutConstraint {
        UILayoutConstraint(constant: Double(self), priority: priority)
    }
}

extension UILayoutPriority: @retroactive ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Float
    public init(floatLiteral value: FloatLiteralType) {
        self.init(rawValue: value)
    }
}

extension UILayoutPriority: @retroactive ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(rawValue: value.float)
    }
}

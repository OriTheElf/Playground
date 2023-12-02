//
//  NSKeyValueObservingOptionsPlus.swift
//  KnowLED
//
//  Created by Choi on 2023/12/2.
//

import Foundation

extension NSKeyValueObservingOptions {
    /// 合并[.initial, .new]
    static let live: NSKeyValueObservingOptions = [.initial, .new]
}

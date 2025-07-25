//
//  Array+Rx.swift
//  RxPlayground
//
//  Created by Choi on 2022/4/20.
//

import UIKit
import RxSwift
import RxCocoa

typealias RxElementFilter<T> = (Int, T) -> Bool

extension Array where Element: ObservableConvertibleType {
    
    var merged: Observable<Element.Element> {
        Observable.from(self).merge()
    }
    
    /// 串联事件序列数组(无时间间隔)
    var chained: Completable {
        chained(pauseInterval: nil)
    }
    
    /// 串联事件序列数组
    /// - Parameters:
    ///   - pauseInterval: 序列之间的停顿时间(首尾的序列不添加停顿时间)
    ///   - scheduler: 执行时间间隔的调度器 | interval非空才有意义
    /// - Returns: Completable
    func chained(pauseInterval: RxTimeInterval? = nil, scheduler: SchedulerType = MainScheduler.instance) -> Completable {
        /// 确保数组非空
        guard isNotEmpty else {
            return .empty()
        }
        /// 间隔序列
        let pause = pauseInterval.map {
            Observable.just(0).delay($0, scheduler: scheduler).completed
        }
        return enumerated().reduce(Completable.empty) { completable, tuple in
            /// 下一个Completable事件序列
            let nextCompletable = tuple.element.completed
            /// 中间的序列
            let isMiddleSequence = tuple.offset != startIndex && tuple.offset != lastIndex
            /// 不是第一个 && 时间间隔非空
            if let pause, isMiddleSequence {
                return completable + pause.andThen(nextCompletable)
            } else {
                return completable + nextCompletable
            }
        }
    }
}

final class RxButtonControlPropertyCoordinator<Button: UIButton, Property: Hashable>: ObservableType {
    /// [属性:按钮]字典
    typealias PropertyButtonMap = [Property: Button]
    /// 合并Button的.valueChanged事件(用于表示用户交互状态下发送出的Property)
    private let userInteractivePropertySequence: Observable<Property>
    /// 按钮映射字典
    private let propertyButtonMap: PropertyButtonMap
    /// DisposeBag
    private let disposeBag = DisposeBag()
    /// 接收并更新属性
    private lazy var propertyBinder = Binder<Property>(self) { weakSelf, property in
        weakSelf.setProperty(property, sendEvent: false, isUserInteractive: false)
    }
    /// 储存元素
    @Variable private var property: Property?
    
    /// 初始化
    /// - Parameters:
    ///   - initialValue: 初始值
    ///   - buttons: 按钮数组
    ///   - keyPath: KeyPath
    ///   - filter: 事件过滤闭包
    init(startWith initialValue: Property?,
         buttons: [Button],
         keyPath: ReferenceWritableKeyPath<Button, Property>,
         filter: RxElementFilter<Button>? = nil)
    {
        /// 建立映射
        var propertyButtonMap = PropertyButtonMap.empty
        /// 储存用户点击(.valueChanged事件)发出的Property事件
        var userInteractiveButtonPropertyEvents = [Observable<Property>].empty
        /// 找出第一个需要选中的按钮
        var firstSelectedButton: Button?
        /// 遍历按钮
        for button in buttons {
            /// 从buttons中找到指定值
            let property = button[keyPath: keyPath]
            /// 更新键值映射
            propertyButtonMap[property] = button
            /// 储存用户点击按钮发送Property事件序列加入数组
            userInteractiveButtonPropertyEvents.append {
                button.rx.controlEvent(.valueChanged).withUnretained(button).map { weakButton, _ in
                    weakButton[keyPath: keyPath]
                }
            }
            /// 如果和初始值匹配则储存为第一个选中按钮
            if initialValue == property {
                firstSelectedButton = button
            }
        }
        /// 更新映射属性
        self.propertyButtonMap = propertyButtonMap
        /// 设置初始值
        self.property = initialValue
        /// 储存为用户交互状态下发出的Property事件
        self.userInteractivePropertySequence = userInteractiveButtonPropertyEvents.merged
        /// 订阅按钮切换逻辑
        self.disposeBag.insert {
            buttons.switchButton(startWith: firstSelectedButton, filter: filter).bind {
                [unowned self] button in
                /// 更新属性并发送事件
                setProperty(button[keyPath: keyPath], sendEvent: true, isUserInteractive: true)
            }
        }
    }
    
    func asObservable() -> Observable<Property> {
        _property.conditionalValue.unwrapped.removeDuplicates
    }
    
    func subscribe<Observer>(_ observer: Observer) -> any Disposable where Observer : ObserverType, Property == Observer.Element {
        asObservable().subscribe(observer)
    }
    
    /// 更新属性
    /// - Parameters:
    ///   - property: 属性新值
    ///   - sendEvent: 是否发送事件
    private func setProperty(_ property: Property, sendEvent: Bool, isUserInteractive: Bool) {
        /// property有变动才执行后续操作
        guard self.property != property else { return }
        /// 更新property
        _property.setValue(property, sendEvent: sendEvent)
        /// 取出目标按钮
        guard let targetButton = propertyButtonMap[property] else { return }
        /// 发送用户交互事件(注意调用顺序)
        if isUserInteractive {
            targetButton.sendActions(for: .valueChanged)
        }
        /// 如果目标按钮未选中, 则执行按钮点击(让switchSelectedButton序列内部处理按钮选中和上一个按钮反选的操作)
        if !targetButton.isSelected {
            /// 执行点击事件
            targetButton.sendActions(for: .touchUpInside)
        }
    }
    
    /// 生成ControlProperty(使用计算属性而不是lazy var避免循环引用)
    var controlProperty: ControlProperty<Property> {
        ControlProperty(values: self, valueSink: propertyBinder)
    }
    
    var userInteractiveControlProperty: ControlProperty<Property> {
        ControlProperty(values: userInteractivePropertySequence, valueSink: propertyBinder)
    }
}

extension Array where Element: UIButton {
    
    /// 按钮数组转换为ControlProperty
    /// - Parameters:
    ///   - initialValue: 初始值
    ///   - keyPath: KeyPath
    ///   - filter: 按钮点击事件过滤闭包
    /// - Returns: ControlProperty
    func controlPropertyCoordinatorSwitchingButtons<Property: Hashable>(
        startWith initialValue: Property? = nil,
        keyPath: ReferenceWritableKeyPath<Element, Property>,
        filter: RxElementFilter<Element>? = nil) -> RxButtonControlPropertyCoordinator<Element, Property>
    {
        RxButtonControlPropertyCoordinator(startWith: initialValue, buttons: self, keyPath: keyPath, filter: filter)
    }
    
    /// 切换选中的按钮
    /// - Parameters:
    ///   - controlEvents: 切换按钮需要执行的事件
    ///   - startIndex: 第一个选中的按钮索引
    ///   - filter: 按钮点击事件过滤闭包
    /// - Returns: 选中的按钮事件序列
    func switchButton(for controlEvents: UIControl.Event = .touchUpInside, startIndex: Index?, filter: RxElementFilter<Element>? = nil) -> Observable<Element> {
        switchButton(for: controlEvents, startWith: element(at: startIndex), filter: filter)
    }
    
    /// 切换选中的按钮
    /// - Parameters:
    ///   - controlEvents: 切换按钮需要执行的事件
    ///   - firstButton: 第一个要选中的按钮
    ///   - filter: 按钮点击事件过滤闭包
    /// - Returns: 选中的按钮事件序列
    func switchButton(for controlEvents: UIControl.Event = .touchUpInside, startWith firstButton: Element? = nil, filter: RxElementFilter<Element>? = nil) -> Observable<Element>
    {
        buttonFor(controlEvents: controlEvents, startWith: firstButton, filter: filter).lastAndLatest.compactMap { lastButton, button -> Element? in
            /// 上一个按钮取消选中
            if let lastButton {
                /// 重复的按钮不发送事件
                if button === lastButton {
                    return nil
                }
                /// 取消选中上一个按钮
                else {
                    lastButton.isSelected = false
                }
            }
            /// 选中最新的按钮
            button.isSelected = true
            /// 返回最新按钮
            return button
        }
    }
    
    /// 合并所有按钮的点击事件 | 按钮点击之后发送按钮对象自己
    /// - Parameters:
    ///   - firstButton: 第一个要选中的按钮
    ///   - filter: 按钮点击事件过滤闭包
    /// - Returns: 按钮事件序列
    fileprivate func buttonFor(controlEvents: UIControl.Event, startWith firstButton: Element?, filter: RxElementFilter<Element>?) -> Observable<Element> {
        /// 第一个发送的按钮
        let filteredFirstButton = firstButton.flatMap { button -> Element? in
            /// 如果有事件过滤
            if let filter {
                /// 查找第一个按钮在数组中的索引. 如果不在数组中则返回空
                guard let index = firstIndex(of: button) else { return nil }
                /// 调用: 评估通过后返回第一个按钮, 否则返回空
                return filter(index, button) ? button : nil
            } else {
                /// 无事件过滤, 直接返回第一个按钮
                return button
            }
        }
        let triggeredButtonSequences = enumerated().map { index, button -> Observable<Element> in
            /// 指定事件触发是发送的Button序列
            let triggeredButton = button.rx.controlEvent(controlEvents).compactMap {
                [weak button] _ in button
            }
            /// 最终返回的序列
            return filter.map(fallback: triggeredButton) { filter in
                triggeredButton.filter {
                    filter(index, $0)
                }
            }
        }
        return triggeredButtonSequences.merged
            .optionalElement
            .startWith(filteredFirstButton)
            .unwrapped
    }
}

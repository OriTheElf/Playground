//
//  UIBaseScrollView.swift
//
//  Created by Choi on 2022/8/15.
//

import UIKit

class UIBaseScrollView: UIScrollView, StandardLayoutLifeCycle {
    
    /// 是否开启: 触摸到UIControl子类的时候阻断滚动视图的滚动
    var doBlockScrollWhenHitUIControls = true
    
    lazy var contentView = defaultContentView
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepare()
    }
    
    /// 避免如像UISlider类似的控件在滑动时被UIScrollView滑动事件阻断的问题
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let receiver = super.hitTest(point, with: event)
        if doBlockScrollWhenHitUIControls {
            let isUIControl = receiver?.isKind(of: UIControl.self) ?? false
            if isUIControl {
                isScrollEnabled = false
            } else {
                isScrollEnabled = true
            }
        }
        return receiver
    }
    
    /// 重写此方法, 可延迟子视图中点击事件, 避免滑动和点击事件冲突
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view.isKind(of: UIControl.self) {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }
    
    func prepare() {
        prepareSubviews()
        prepareConstraints()
        contentInsetAdjustmentBehavior = .automatic
        keyboardDismissMode = .interactive
        backgroundColor = .clear
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }
    
    func prepareSubviews() {
        addSubview(contentView)
    }
    
    func prepareConstraints() {
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    var defaultContentView: UIView {
        UIView()
    }
}
//
//  UIStackScrollView.swift
//
//  Created by Choi on 2022/8/15.
//

import UIKit
import RxSwift

class UIStackScrollView: UIBaseScrollView {
    
    lazy var stackView = UIStackView(axis: Self.scrollableAxis, distribution: .fill, alignment: .fill, spacing: 0.0)
    
    private var observingStackViewNaturalSize: DisposeBag?
    
    override func prepare() {
        super.prepare()
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }
    
    override func makeContentView() -> UIView {
        stackView
    }
}

extension UIStackScrollView {
    
    convenience init(axis: NSLayoutConstraint.Axis, spacing: Double = 0, @ArrayBuilder<UIView> subviewsBuilder: () -> [UIView] = { [] }) {
        let arrangedSubviews = subviewsBuilder()
        self.init(axis: axis, spacing: spacing, arrangedSubviews: arrangedSubviews)
    }
    
    convenience init(
        distribution: UIStackView.Distribution = .fill,
        alignment: UIStackView.Alignment = .fill,
        spacing: CGFloat = 0,
        @ArrayBuilder<UIView> subviewsBuilder: () -> [UIView] = { [] }) {
            let arrangedSubviews = subviewsBuilder()
            self.init(axis: Self.scrollableAxis, distribution: distribution, alignment: alignment, spacing: spacing, arrangedSubviews: arrangedSubviews)
        }
    
    convenience init(
        axis: NSLayoutConstraint.Axis,
        distribution: UIStackView.Distribution = .fill,
        alignment: UIStackView.Alignment = .fill,
        spacing: CGFloat = 0,
        arrangedSubviews: [UIView] = .empty) {
            self.init(frame: .zero)
            self.axis = axis
            self.distribution = distribution
            self.alignment = alignment
            self.spacing = spacing
            self.stackView.reArrangedSubviews = arrangedSubviews
        }
    
    var axis: NSLayoutConstraint.Axis {
        get { stackView.axis }
        set { stackView.axis = newValue }
    }
    
    var distribution: UIStackView.Distribution {
        get { stackView.distribution }
        set { stackView.distribution = newValue }
    }
    
    var alignment: UIStackView.Alignment {
        get { stackView.alignment }
        set { stackView.alignment = newValue }
    }
    
    var spacing: Double {
        get { stackView.spacing }
        set { stackView.spacing = newValue }
    }
    
    var contentInsets: UIEdgeInsets? {
        get { stackView.contentInsets }
        set { stackView.contentInsets = newValue }
    }
    
    func reArrangeSubviews(@ArrayBuilder<UIView> subviewsBuilder: () -> [UIView]) {
        stackView.reArrange(subviewsBuilder)
    }
    
    func reArrangeSubviews(_ arrangedSubviews: [UIView]) {
        stackView.reArrange(arrangedSubviews)
    }
    
    func addArrangedSubviews(_ subviews: [UIView]) {
        subviews.forEach { subview in
            addArrangedSubview(subview)
        }
    }
    
    func addArrangedSubview(_ subview: UIView) {
        stackView.addArrangedSubview(subview)
    }
    
    func setAutoResize(_ autoResize: Bool) {
        let stretchAxis = Self.scrollableAxis
        if autoResize {
            observingStackViewNaturalSize = DisposeBag {
                stackView.rx.naturalSize.bind {
                    [unowned self] naturalSize in
                    switch stretchAxis {
                    case .horizontal:
                        fix(widthConstraint: naturalSize.width.constraint(priority: .defaultHigh))
                    case .vertical:
                        fix(heightConstraint: naturalSize.height.constraint(priority: .defaultHigh))
                    @unknown default:
                        fatalError("Unhandled condition")
                    }
                }
            }
        } else {
            observingStackViewNaturalSize = nil
            switch stretchAxis {
            case .horizontal:
                fix(width: nil)
            case .vertical:
                fix(height: nil)
            @unknown default:
                fatalError("Unhandled condition")
            }
        }
    }
}

typealias UIVStackScrollView = UIStackScrollView

class UIHStackScrollView: UIStackScrollView {
    final override class var scrollableAxis: NSLayoutConstraint.Axis { .horizontal }
}

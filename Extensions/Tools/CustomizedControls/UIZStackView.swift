//
//  UIZStackView.swift
//  FangLiLai
//
//  Created by Major on 2022/3/14.
//  Copyright © 2022 Zhiwu. All rights reserved.
//

import UIKit

class UIZStackView: UIStackView {
	
	var zAlignment: Alignment = .center
	
	private var largestSubView: UIView?
	
	override var intrinsicContentSize: CGSize {
		largestSubView?.frame.size ?? super.intrinsicContentSize
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		zLayoutSubviews()
	}
	
	private func zLayoutSubviews() {
		
		/// 子视图根据frame.size排序
		let soredSubviews = arrangedSubviews.sorted { lhs, rhs in
			lhs.frame.size <= rhs.frame.size
		}
		
		/// 选出最大的子视图
		largestSubView = soredSubviews.last
		
		/// 自定义布局子视图
		soredSubviews.forEach { subview in
			switch zAlignment {
			case .center:
				subview.center = self.center
			case .leading:
				subview.center = self.center
				switch UIApplication.shared.userInterfaceLayoutDirection {
				case .leftToRight:
					subview.frame.origin.x = 0
				case .rightToLeft:
					subview.frame.origin.x = largestSubView.ifNil(bounds.size.width, else: \.frame.size.width) - subview.frame.size.width
				@unknown default:
					break
				}
			case .trailing:
				subview.center = self.center
				switch UIApplication.shared.userInterfaceLayoutDirection {
				case .leftToRight:
					subview.frame.origin.x = largestSubView.ifNil(bounds.size.width, else: \.frame.size.width) - subview.frame.size.width
				case .rightToLeft:
					subview.frame.origin.x = 0
				@unknown default:
					break
				}
			case .top:
				subview.center = self.center
				subview.frame.origin.y = 0
			case .bottom:
				subview.center = self.center
				subview.frame.origin.y = 0
			case .topLeading:
				subview.center = self.center
				subview.frame.origin.y = 0
				switch UIApplication.shared.userInterfaceLayoutDirection {
				case .leftToRight:
					subview.frame.origin.x = 0
				case .rightToLeft:
					subview.frame.origin.x = largestSubView.ifNil(bounds.size.width, else: \.frame.size.width) - subview.frame.size.width
				@unknown default:
					break
				}
			case .topTrailing:
				subview.center = self.center
				subview.frame.origin.y = 0
				switch UIApplication.shared.userInterfaceLayoutDirection {
				case .leftToRight:
					subview.frame.origin.x = largestSubView.ifNil(bounds.size.width, else: \.frame.size.width) - subview.frame.size.width
				case .rightToLeft:
					subview.frame.origin.x = 0
				@unknown default:
					break
				}
			case .bottomLeading:
				subview.center = self.center
				subview.frame.origin.y = largestSubView.ifNil(bounds.size.height, else: \.frame.size.height) - subview.frame.size.height
				switch UIApplication.shared.userInterfaceLayoutDirection {
				case .leftToRight:
					subview.frame.origin.x = 0
				case .rightToLeft:
					subview.frame.origin.x = largestSubView.ifNil(bounds.size.width, else: \.frame.size.width) - subview.frame.size.width
				@unknown default:
					break
				}
			case .bottomTrailing:
				subview.center = self.center
				subview.frame.origin.y = largestSubView.ifNil(bounds.size.height, else: \.frame.size.height) - subview.frame.size.height
				switch UIApplication.shared.userInterfaceLayoutDirection {
				case .leftToRight:
					subview.frame.origin.x = largestSubView.ifNil(bounds.size.width, else: \.frame.size.width) - subview.frame.size.width
				case .rightToLeft:
					subview.frame.origin.x = 0
				@unknown default:
					break
				}
			}
		}
		
		/// 如果最大子视图不为空则使intrinsicContentSize失效
		if let _ = largestSubView {
			invalidateIntrinsicContentSize()
		}
	}
}

extension UIZStackView {
	enum Alignment {
		case center
		case leading
		case trailing
		case top
		case bottom
		case topLeading
		case topTrailing
		case bottomLeading
		case bottomTrailing
	}
}

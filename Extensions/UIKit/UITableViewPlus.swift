//
//  UITableViewPlus.swift
//  ExtensionDemo
//
//  Created by Choi on 2021/3/15.
//  Copyright © 2021 Choi. All rights reserved.
//

import UIKit

extension UITableView {
	
    var numberOfRows: Int {
        (0..<numberOfSections).reduce(0) { rowCount, section in
            rowCount + numberOfRows(inSection: section)
        }
    }
    
    func performAllCellSelection(_ performSelection: Bool) {
        for section in 0..<numberOfSections {
            for row in 0..<numberOfRows(inSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                if let cell = cellForRow(at: indexPath) {
                    if performSelection {
                        /// 未选中的行才执行选中操作,避免重复调用
                        if !cell.isSelected {
                            _ = delegate?.tableView?(self, willSelectRowAt: indexPath)
                            selectRow(at: indexPath, animated: false, scrollPosition: .none)
                            delegate?.tableView?(self, didSelectRowAt: indexPath)
                        }
                    } else {
                        /// 选中的行才执行反选操作,避免重复调用
                        if cell.isSelected {
                            _ = delegate?.tableView?(self, willDeselectRowAt: indexPath)
                            deselectRow(at: indexPath, animated: false)
                            delegate?.tableView?(self, didDeselectRowAt: indexPath)
                        }
                    }
                }
            }
        }
    }
    
	/// 在视图控制器的viewDidLayoutSubviews()方法里调用此方法以自动布局HeaderFooterView
	func layoutHeaderFooterViewIfNeeded() {
		if let headerView = tableHeaderView {
			let fitSize = CGSize(width: bounds.size.width, height: UIView.layoutFittingCompressedSize.height)
			let layoutSize = headerView.systemLayoutSizeFitting(fitSize)
			guard headerView.frame.size != layoutSize else { return }
			headerView.frame.size = layoutSize
			tableHeaderView = headerView
		}
		if let footerView = tableFooterView {
			let fitSize = CGSize(width: bounds.size.width, height: UIView.layoutFittingCompressedSize.height)
			let layoutSize = footerView.systemLayoutSizeFitting(fitSize)
			guard footerView.frame.size != layoutSize else { return }
			footerView.frame.size = layoutSize
			tableFooterView = footerView
		}
	}
}

extension UITableViewCell: ReusableView {}
extension UITableViewCell {
	static func registerFor(_ tableView: UITableView) {
		tableView.register(self, forCellReuseIdentifier: reuseId)
	}
	static func dequeueReusableCell(from tableView: UITableView, indexPath: IndexPath) -> Self {
		tableView.dequeueReusableCell(withIdentifier: Self.reuseId, for: indexPath) as! Self
	}
}

extension UITableViewHeaderFooterView: ReusableView {}
extension UITableViewHeaderFooterView {
	static func registerFor(_ tableView: UITableView) {
		tableView.register(self, forHeaderFooterViewReuseIdentifier: reuseId)
	}
	static func dequeueReusableHeaderFooterView(from tableView: UITableView) -> Self? {
		tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseId) as? Self
	}
}

// MARK: - KK<UITableView>
extension KK where Base: UITableView {
    
    /// 刷新列表
    /// - Parameter keepLastSelections: 重新选择上次选中的行
    func reloadData(keepLastSelections: Bool) {
        if keepLastSelections, let lastSelections = base.indexPathsForSelectedRows {
            base.reloadData()
            lastSelections.forEach { indexPath in
                base.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        } else {
            base.reloadData()
        }
    }
}

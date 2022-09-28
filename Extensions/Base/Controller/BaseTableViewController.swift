//
//  BaseTableViewController.swift
//  zeniko
//
//  Created by Choi on 2022/8/2.
//  Copyright © 2022 GODOX Photo Equipment Co.,Ltd. All rights reserved.
//

import UIKit

class BaseTableViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
	lazy var tableView = makeTableView()
    
    lazy var emptyView = ZKTableViewEmptyView()
    
    var tableViewStyle: UITableView.Style { .plain }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// 配置TableView
        configureTableView()
        /// 添加TableView
        addTableView()
    }
    
    /// 添加TableView
    /// 调用时机:viewDidLoad()
    func addTableView() {
        tableView.frame = view.bounds
        view.addSubview(tableView)
    }
    
    /// 调用时机:viewDidLoad()
    func configureTableView() {
        if #available(iOS 15, *) {
            /// 取消组头顶部间距
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.backgroundView = emptyView
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.estimatedRowHeight = 40.0
        
        /// 占位图默认隐藏
        emptyView.isHidden = true
        
        UITableViewCell.registerFor(tableView)
        UITableViewHeaderFooterView.registerFor(tableView)
    }
    
    /// 调用时机:懒加载
    func makeTableView() -> UITableView {
        let table = UITableView(frame: .zero, style: tableViewStyle)
        table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        table.delegate = self
        table.dataSource = self
        return table
    }
    // MARK: - Table View Delegate
    // 注意: 必须父类里有实现,代理方法才会调用
    /// 分组数
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    /// 每组行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
    /// 组头高度
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    /// 组头估算高度
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat { 50.0 }
    /// 每行高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /// 不使用UITableView.automaticDimension
        /// 为了消除警告:
        /// Warning once only: Detected a case where constraints ambiguously suggest a height of zero for a table view cell's content view.
        /// We're considering the collapse unintentional and using standard height instead.
        .leastNormalMagnitude
    }
    /// 每行估算高度
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 50.0 }
    /// 组尾高度
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    /// 组尾估算高度
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat { 50.0 }
    /// 选中一行
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
    
    /// 组头
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UITableViewHeaderFooterView.dequeueReusableHeaderFooterView(from: tableView)
    }
    
    /// Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell.dequeueReusableCell(from: tableView, indexPath: indexPath)
    }
    
    /// 组尾
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UITableViewHeaderFooterView.dequeueReusableHeaderFooterView(from: tableView)
    }
    
    /// 显示Cell
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {}
    
    /// 缩进
    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int { 0 }
}

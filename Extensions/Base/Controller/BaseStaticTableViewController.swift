//
//  BaseStaticTableViewController.swift
//
//  Created by Choi on 2022/8/11.
//

import UIKit
import RxSwift

class BaseStaticTableViewController<StaticTable: UIBaseStaticTable>: BaseTableViewController {
    
    lazy var staticTable = StaticTable()
    
    override func makeTableView() -> UITableView {
        staticTable.configure { table in
            table.autoresizingMask = .autoResize
            table.backgroundColor = baseViewBackgroundColor
        }
    }
}

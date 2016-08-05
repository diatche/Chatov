//
//  ViewController.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 5/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet weak var tableView : UITableView!
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    func setupTableView() {

        let messages = Observable.just([
            "hey",
            "what up?"
        ])

        messages.bindTo(tableView.rx_itemsWithCellIdentifier("Cell", cellType: MessageTableViewCell.self)) { (row, message, cell) in
            cell.textLabel?.text = message
        }
        .addDisposableTo(disposeBag)
    }
}


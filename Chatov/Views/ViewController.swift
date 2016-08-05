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
import NextGrowingTextView

class ViewController: UIViewController {

    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var inputContainerViewBottom : NSLayoutConstraint!
    @IBOutlet weak var inputContainerView : UIView!
    @IBOutlet weak var inputTextView : NextGrowingTextView!
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupInputView()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func setupTableView() {
        tableView.contentInset.bottom = inputContainerView.frame.size.height
        tableView.scrollIndicatorInsets.bottom = inputContainerView.frame.size.height

        let messages = Manager.sharedInstance.messages.asObservable()

        messages.bindTo(tableView.rx_itemsWithCellIdentifier("Cell", cellType: MessageTableViewCell.self)) { (row, message, cell) in
            cell.textLabel?.text = message.text
        }
        .addDisposableTo(disposeBag)
    }

    func setupInputView() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)

        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        inputTextView.placeholderAttributedText = NSAttributedString(string: "Ваше сообщение...",
                                                                     attributes: [NSFontAttributeName: inputTextView.font!,
                                                                        NSForegroundColorAttributeName: UIColor.lightGrayColor()])
    }

    func keyboardWillHide(sender: NSNotification) {
        if let userInfo = sender.userInfo {
            if let _ = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size.height {
                self.inputContainerViewBottom.constant = 0
                self.tableView.contentInset.bottom = self.inputContainerView.frame.size.height
                self.tableView.scrollIndicatorInsets.bottom = self.inputContainerView.frame.size.height
                UIView.animateWithDuration(0.25) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    func keyboardWillShow(sender: NSNotification) {
        if let userInfo = sender.userInfo {
            if let keyboardHeight = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size.height {
                self.inputContainerViewBottom.constant = keyboardHeight
                self.tableView.contentInset.bottom = keyboardHeight + self.inputContainerView.frame.size.height
                self.tableView.scrollIndicatorInsets.bottom = keyboardHeight + self.inputContainerView.frame.size.height
                UIView.animateWithDuration(0.25) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    @IBAction func sendMessageAction() {
        Presenter.sharedInstance.sendTextMessage(inputTextView.text)
        inputTextView.text = ""
    }
}


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
    @IBOutlet weak var sendButton : UIButton!
    @IBOutlet weak var cameraButton : UIButton!
    @IBOutlet weak var imagesButton : UIButton!
    @IBOutlet weak var geoButton : UIButton!
    var disposeBag = DisposeBag()
    var lastKeyboardHeight : CGFloat = 0

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
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension

        // Bind cells to messages
        let messages = Manager.sharedInstance.messages.asObservable()
        messages.bindTo(tableView.rx_itemsWithCellIdentifier("Cell", cellType: MessageTableViewCell.self)) { (row, message, cell) in
            cell.messageTextLabel.text = message.text

            let numberOfRows = self.tableView.numberOfRowsInSection(0)
            cell.isShowingBubbleTail = (numberOfRows == 0 || row == numberOfRows - 1)
        }
        .addDisposableTo(disposeBag)

        // Scroll when new messages arrive
        messages
            .throttle(0.2, scheduler: MainScheduler.instance)
            .subscribeNext { _ in
                self.scrollToEndIfNeeded()
            }
            .addDisposableTo(disposeBag)
    }

    func setupInputView() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)

        inputTextView.textContainerInset = UIEdgeInsets(top: 14, left: 6, bottom: 14, right: 8)
        inputTextView.placeholderAttributedText = NSAttributedString(string: "Ваше сообщение...",
                                                                     attributes: [NSFontAttributeName: inputTextView.font!,
                                                                        NSForegroundColorAttributeName: UIColor.lightGrayColor()])

        sendButton.enabled = false
        inputTextView.delegates.textViewDidChange = { [unowned self] textView in
            self.sendButton.enabled = (textView.text.characters.count != 0)
        }

        inputTextView.delegates.didChangeHeight = { [unowned self] textView in
            self.updateWithLastKeyboardHeight()
        }

        sendButton.rx_tap.subscribeNext { [unowned self] _ in
            Presenter.sharedInstance.sendTextMessage(self.inputTextView.text)
            self.inputTextView.text = ""
            self.inputTextView.becomeFirstResponder()
        }
        .addDisposableTo(disposeBag)
    }

    func keyboardWillHide(sender: NSNotification) {
        if let userInfo = sender.userInfo {
            if let _ = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size.height {
                updateWithKeyboardHeight(0)
            }
        }
    }

    func keyboardWillShow(sender: NSNotification) {
        if let userInfo = sender.userInfo {
            if let keyboardHeight = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size.height {
                updateWithKeyboardHeight(keyboardHeight)
            }
        }
    }

    func updateWithKeyboardHeight(keyboardHeight: CGFloat) {
        self.inputContainerViewBottom.constant = keyboardHeight
        self.tableView.contentInset.bottom = keyboardHeight + self.inputContainerView.frame.size.height
        self.tableView.scrollIndicatorInsets.bottom = keyboardHeight + self.inputContainerView.frame.size.height
        UIView.animateWithDuration(0.25) {
            self.view.layoutIfNeeded()
        }
        scrollToEndIfNeeded()

        lastKeyboardHeight = keyboardHeight
    }

    func updateWithLastKeyboardHeight() {
        updateWithKeyboardHeight(lastKeyboardHeight)
    }

    func scrollToEndIfNeeded() {
        let numberOfMessages = tableView.numberOfRowsInSection(0)
        guard let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows where numberOfMessages > 1
            else { return }

        if indexPathsForVisibleRows.contains(NSIndexPath(forRow: numberOfMessages - 2, inSection:0)) {
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: numberOfMessages - 1, inSection:0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
        else if indexPathsForVisibleRows.contains(NSIndexPath(forRow: 0, inSection:0)) {
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: numberOfMessages - 1, inSection:0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
        }
    }

    static func previousIndexPathInSection(indexPath: NSIndexPath) -> NSIndexPath {
        return NSIndexPath(forRow: max(indexPath.row - 1 as Int, 0), inSection: indexPath.section)
    }
}


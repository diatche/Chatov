//
//  MessagesViewController.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 5/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import NextGrowingTextView
import MapKit

class MessagesViewController: UIViewController {

    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var inputContainerViewBottom : NSLayoutConstraint!
    @IBOutlet weak var inputContainerView : UIView!
    @IBOutlet weak var inputTextView : NextGrowingTextView!
    @IBOutlet weak var sendButton : UIButton!
    @IBOutlet weak var cameraButton : UIButton!
    @IBOutlet weak var imagesButton : UIButton!
    @IBOutlet weak var geoButton : UIButton!
    @IBOutlet weak var imagePickerContainerView : UIView!
    @IBOutlet var imagePickerContainerHeight : NSLayoutConstraint!

    var disposeBag = DisposeBag()
    var lastKeyboardHeight : CGFloat = 0
    var lastMessageInputHeight : CGFloat = 0
    var isShowingImagePicker = false
    var isShowingCamera = false
    var isShowingImagePickerFullscreen = false
    var cameraViewController : CameraViewController?
    var photoViewController : PhotoViewController?

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
        let messages = MessageManager.sharedInstance.messages.asObservable()
        messages.bindTo(tableView.rx_itemsWithCellFactory) { (tableView, row, message) in
            let cell: MessageTableViewCell

            if message.coordinateIsValid {
                let mapCell = tableView.dequeueReusableCellWithIdentifier("MapCell") as! MapMessageTableViewCell
                mapCell.annotation = message

                cell = mapCell
            }
            else if message.image != nil || message.imageUrl != nil {
                let imageCell = tableView.dequeueReusableCellWithIdentifier("ImageCell") as! ImageMessageTableViewCell
                imageCell.messageImageView.image = nil
                Presenter.sharedInstance.receiveImageInMessage(message).subscribeNext { image in
                    imageCell.messageImageView.image = image
                }
                .addDisposableTo(imageCell.disposeBag)

                cell = imageCell
            }
            else {
                let textCell = tableView.dequeueReusableCellWithIdentifier("TextCell") as! TextMessageTableViewCell
                textCell.messageTextLabel.text = message.text

                cell = textCell
            }

            let numberOfRows = self.tableView.numberOfRowsInSection(0)
            cell.isShowingBubbleTail = (numberOfRows == 0 || row == numberOfRows - 1)
            return cell
        }
        .addDisposableTo(disposeBag)

        // Scroll when new messages arrive
        messages
            .throttle(0.2, scheduler: MainScheduler.instance)
            .delaySubscription(0.1, scheduler: MainScheduler.instance)
            .subscribeNext { _ in
                CATransaction.begin()
                CATransaction.setCompletionBlock({ () -> Void in
                    self.scrollToEndIfNeeded()
                })
                CATransaction.commit()
            }
            .addDisposableTo(disposeBag)
    }

    func setupInputView() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessagesViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessagesViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)

        inputTextView.textContainerInset = UIEdgeInsets(top: 14, left: 6, bottom: 14, right: 8)
        inputTextView.placeholderAttributedText = NSAttributedString(string: "Ваше сообщение...",
                                                                     attributes: [NSFontAttributeName: inputTextView.font!,
                                                                        NSForegroundColorAttributeName: UIColor.lightGrayColor()])

        inputTextView.delegates.textViewDidBeginEditing = { [unowned self] textView in
            self.editMessage()
        }

        sendButton.enabled = false
        inputTextView.delegates.textViewDidChange = { [unowned self] textView in
            self.sendButton.enabled = (textView.text.characters.count != 0)
        }

        inputTextView.delegates.didChangeHeight = { [unowned self] height in
            if self.lastMessageInputHeight != height {
                self.updateWithLastKeyboardHeight()
                self.lastMessageInputHeight = height
            }
        }

        sendButton.rx_tap.subscribeNext { [unowned self] _ in
            Presenter.sharedInstance.sendTextMessage(self.inputTextView.text)
            self.inputTextView.text = ""
            self.inputTextView.becomeFirstResponder()
        }
        .addDisposableTo(disposeBag)

        cameraButton.rx_tap.subscribeNext {
            self.showImagePicker(withCamera: true)
        }
        .addDisposableTo(disposeBag)

        imagesButton.rx_tap.subscribeNext {
            self.showImagePicker(withCamera: false)
        }
        .addDisposableTo(disposeBag)

        geoButton.rx_tap.subscribeNext {
            Presenter.sharedInstance.sendGeoLocation()
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

        UIView.animateWithDuration(0.25, delay: 0, options: .BeginFromCurrentState, animations: {
            self.view.layoutIfNeeded()
            let inset = keyboardHeight + self.inputContainerView.frame.size.height
            self.tableView.contentInset.bottom = inset
            self.tableView.scrollIndicatorInsets.bottom = inset
        }, completion: { _ in
            if !self.isShowingImagePicker {
                self.resetImagePicker()
            }
        })
        scrollToEndIfNeeded()

        lastKeyboardHeight = keyboardHeight
    }

    func updateWithLastKeyboardHeight() {
        updateWithKeyboardHeight(lastKeyboardHeight)
    }

    func editMessage() {
        hideImagePicker()
        updateWithLastKeyboardHeight()
    }

    func showImagePicker(withCamera useCamera: Bool) {
        if !isShowingImagePicker || isShowingCamera != useCamera {
            resetImagePicker()
            if useCamera {
                setupCameraViewController()
            }
            else {
                setupPhotoViewController()
            }
        }

        isShowingCamera = useCamera
        isShowingImagePicker = true

        imagePickerContainerHeight.active = false

        imagePickerContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[picker]|",
            options: [],
            metrics: nil,
            views: ["picker": (cameraViewController ?? photoViewController)!.view]))

        imagePickerContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[picker]|",
            options: [],
            metrics: nil,
            views: ["picker": (cameraViewController ?? photoViewController)!.view]))

        inputTextView.resignFirstResponder()

        updateWithLastKeyboardHeight()

    }

    func setupCameraViewController() {
        cameraViewController = CameraViewController()
        addChildViewController(cameraViewController!)
        imagePickerContainerView.addSubview(cameraViewController!.view)
    }

    func setupPhotoViewController() {
        photoViewController = PhotoViewController()
        addChildViewController(photoViewController!)
        imagePickerContainerView.addSubview(photoViewController!.view)
    }

    func hideImagePicker() {
        imagePickerContainerView.removeConstraints(imagePickerContainerView.constraints.filter { $0 != imagePickerContainerHeight })
        imagePickerContainerHeight.active = true
        isShowingImagePicker = false
    }

    func resetImagePicker() {
        imagePickerContainerView.subviews.forEach { $0.removeFromSuperview() }

        cameraViewController?.removeFromParentViewController()
        cameraViewController = nil

        photoViewController?.removeFromParentViewController()
        photoViewController = nil
    }

    func scrollToEndIfNeeded() {
        let numberOfMessages = tableView.numberOfRowsInSection(0)
        guard let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows where numberOfMessages > 1
            else { return }

        if indexPathsForVisibleRows.contains(NSIndexPath(forRow: numberOfMessages - 2, inSection:0)) {
            let contentOffset = tableView.contentSize.height - tableView.frame.height + tableView.contentInset.bottom
            tableView.setContentOffset(CGPointMake(0, contentOffset), animated: true)
        }
        else if indexPathsForVisibleRows.contains(NSIndexPath(forRow: 0, inSection:0)) {
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: numberOfMessages - 1, inSection:0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
        }
    }

    static func previousIndexPathInSection(indexPath: NSIndexPath) -> NSIndexPath {
        return NSIndexPath(forRow: max(indexPath.row - 1 as Int, 0), inSection: indexPath.section)
    }
}


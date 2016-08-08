//
//  CameraViewController.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 8/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CameraViewController: UIImagePickerController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var fullscreenButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var swapButton: UIButton!
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = true

        sourceType = .Camera
        showsCameraControls = false
        delegate = self

        captureButton.rx_tap.subscribeNext { [unowned self] _ in
            self.takePicture()
        }
        .addDisposableTo(disposeBag)
    }

    func CameraViewController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            Presenter.sharedInstance.sendImage(image)
        }
    }
}

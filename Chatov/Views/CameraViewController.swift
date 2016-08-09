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

    var fullscreenButton: UIButton?
    var captureButton: UIButton?
    var swapButton: UIButton?
    var stackView: UIStackView?

    let disposeBag = DisposeBag()

    let wantsFullscreen = Variable<Bool>(false)

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        if UIImagePickerController.availableMediaTypesForSourceType(.Camera)?.count ?? 0 != 0 {
            sourceType = .Camera
            showsCameraControls = false

            fullscreenButton = UIButton()
            fullscreenButton!.setImage(UIImage(named: "camera_interface_fullscreen"), forState: .Normal)
            fullscreenButton!.setImage(UIImage(named: "fullscreen_close"), forState: .Selected)
            fullscreenButton!.addTarget(self, action: #selector(fullscreenToggle), forControlEvents: UIControlEvents.TouchUpInside)

            captureButton = UIButton()
            captureButton!.setTitle("Отпр", forState: .Normal)
            captureButton!.addTarget(self, action: #selector(takePicture), forControlEvents: UIControlEvents.TouchUpInside)

            swapButton = UIButton()
            swapButton!.setImage(UIImage(named: "camera_interface_switch"), forState: .Normal)
            swapButton!.addTarget(self, action: #selector(swapCamera), forControlEvents: UIControlEvents.TouchUpInside)

            stackView = UIStackView(arrangedSubviews: [fullscreenButton!, captureButton!, swapButton!])
            stackView!.distribution = .FillEqually
            cameraOverlayView = stackView
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let superBounds = view.superview?.bounds,
        let stackView = self.stackView
            else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Scale to fill
        var newFrame = CGRect()
        if superBounds.width / 3 > superBounds.height / 4 {
            newFrame.size.width = superBounds.width
            newFrame.size.height = superBounds.width / 3.0 * 4.0
            newFrame.origin.y = (superBounds.height - newFrame.height) / 2
        }
        else {
            newFrame.size.height = superBounds.height
            newFrame.size.width = superBounds.height / 4.0 * 3.0
            newFrame.origin.x = (superBounds.width - newFrame.width) / 2
        }
        self.view.frame = newFrame

        var buttonFrame = CGRect()
        buttonFrame.size.width = superBounds.width
        buttonFrame.size.height = 60
        buttonFrame.origin.x = -newFrame.minX
        buttonFrame.origin.y = newFrame.maxY - buttonFrame.height
        stackView.frame = buttonFrame

        CATransaction.commit()
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Fix orientation
            let fixedImage = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation: image.imageOrientation)
            Presenter.sharedInstance.sendImage(fixedImage)
        }
    }

    func swapCamera() {
        if cameraDevice == .Front {
            cameraDevice = .Rear
        }
        else {
            cameraDevice = .Front
        }
    }

    func fullscreenToggle() {
        wantsFullscreen.value = !wantsFullscreen.value
        fullscreenButton?.selected = wantsFullscreen.value
    }
}

//
//  PhotoViewController.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 9/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import UIKit
import Photos
import RxSwift
import RxCocoa

/// Displays the users images in the photo library
class PhotoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var collectionView: UICollectionView!
    private let assets = Variable<[PHAsset]>([])
    private var disposeBag = DisposeBag()
    private let cachingImageManager = PHCachingImageManager()
    var itemHeight: CGFloat = 100

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        bindToData()
    }

    func bindToData() {
        assets.asObservable().subscribeNext { newAssets in
            self.cachingImageManager.stopCachingImagesForAllAssets()
            self.cachingImageManager.startCachingImagesForAssets(newAssets,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .AspectFit,
                options: nil
            )
            }
            .addDisposableTo(disposeBag)



        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        var currentAssets = [PHAsset]()
        PHAsset.fetchAssetsWithMediaType(.Image, options: options).enumerateObjectsUsingBlock { (object, _, _) in
            if let asset = object as? PHAsset {
                currentAssets.append(asset)
            }
        }
        
        assets.value = currentAssets
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Horizontal
        layout.itemSize = CGSize(width: itemHeight, height: itemHeight)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.showsHorizontalScrollIndicator = false

        let albumButton = UIButton()
        albumButton.setTitle("Выбрать фото из галереи", forState: .Normal)
        albumButton.setTitleColor(UIColor(red: 0.114, green: 0.533, blue: 0.980, alpha: 1.00), forState: .Normal)
        albumButton.addTarget(self, action: #selector(presentImagePickerController), forControlEvents: .TouchUpInside)
        albumButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(albumButton)

        let divider = UIView()
        divider.backgroundColor = UIColor(red: 0.796, green: 0.796, blue: 0.796, alpha: 1.00)
        divider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(divider)

        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[collectionView]|",
            options: [],
            metrics: nil,
            views: ["collectionView": collectionView]))

        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[albumButton]|",
            options: [],
            metrics: nil,
            views: ["albumButton": albumButton]))

        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[divider]|",
            options: [],
            metrics: nil,
            views: ["divider": divider]))

        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView(itemHeight)]-8-[divider(1)][albumButton(44)]|",
            options: [],
            metrics: ["itemHeight": itemHeight],
            views: ["collectionView": collectionView, "albumButton": albumButton, "divider": divider]))

        view.translatesAutoresizingMaskIntoConstraints = false

        collectionView.registerClass(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")

        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.resizeMode = .Fast

        assets.asObservable().bindTo(collectionView.rx_itemsWithCellIdentifier("Cell", cellType: PhotoCollectionViewCell.self)) { (row, asset, cell) in
            let manager = PHImageManager.defaultManager()

            if cell.tag != 0 {
                manager.cancelImageRequest(PHImageRequestID(cell.tag))
            }

            cell.tag = Int(manager.requestImageForAsset(asset,
                targetSize: layout.itemSize,
                contentMode: .AspectFill,
                options: imageRequestOptions) { (result, _) in
                    cell.imageView.image = result
                })
        }
        .addDisposableTo(disposeBag)

        collectionView.rx_modelSelected(PHAsset.self).subscribeNext { asset in
            PHImageManager.defaultManager().requestImageDataForAsset(asset, options: nil, resultHandler: { (imageData, dataUTI, orientation, info) in
                let image = UIImage(data: imageData!)!
                // Fix orientation
                let fixedImage = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation: orientation)
                Presenter.sharedInstance.sendImage(fixedImage)
            })
        }
        .addDisposableTo(disposeBag)
    }

    func presentImagePickerController() {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = .PhotoLibrary

        self.presentViewController(controller, animated: true, completion: nil)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Fix orientation
            let fixedImage = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation: image.imageOrientation)
            Presenter.sharedInstance.sendImage(fixedImage)
        }
        self.presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
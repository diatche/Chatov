//
//  PhotoCollectionViewCell.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 9/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell : UICollectionViewCell {

    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        imageView.contentMode = .ScaleToFill
        contentView.addSubview(imageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = contentView.bounds
    }
}

//
//  ImageMessageTableViewCell.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 8/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import UIKit

class ImageMessageTableViewCell : MessageTableViewCell {

    @IBOutlet weak var messageImageView : UIImageView!

    override func setup() {
        super.setup()
        contentView.backgroundColor = UIColor(red: 0.796, green: 0.796, blue: 0.796, alpha: 1.00)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutMaskWithContentFrame(UIEdgeInsetsInsetRect(messageImageView.frame, UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
    }
}

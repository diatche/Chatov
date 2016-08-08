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

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutMaskWithContentFrame(UIEdgeInsetsInsetRect(messageImageView.frame, UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
    }
}

//
//  TextMessageTableViewCell.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 8/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import UIKit

class TextMessageTableViewCell : MessageTableViewCell {

    @IBOutlet weak var messageTextLabel : UILabel!

    override func setup() {
        super.setup()

        contentView.backgroundColor = UIColor(red: 0.114, green: 0.533, blue: 0.980, alpha: 1.00)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        bubbleImageView.frame = UIEdgeInsetsInsetRect(messageTextLabel.frame, UIEdgeInsets(top: -8, left: -12, bottom: -8, right: -12))

        layoutBubbleTailImageView()
    }
}

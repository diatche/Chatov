//
//  MessageTableViewCell.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 5/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import UIKit

class MessageTableViewCell : UITableViewCell {

    @IBOutlet weak var messageTextLabel : UILabel!
    @IBOutlet weak var bubbleTailImageView : UIImageView!

    var isShowingBubbleTail : Bool = false {
        didSet {
            bubbleTailImageView.hidden = !isShowingBubbleTail
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    func setup() {
        backgroundColor = UIColor.clearColor()
        contentView.backgroundColor = UIColor.clearColor()
        isShowingBubbleTail = false
    }
}
//
//  MessageTableViewCell.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 5/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import UIKit

class MessageTableViewCell : UITableViewCell {

    let bubbleImageView = UIImageView()
    let bubbleTailImageView = UIImageView()

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
        bubbleImageView.image = UIImage(named: "bubble")
        bubbleTailImageView.image = UIImage(named: "bubble_tail")

        bubbleImageView.translatesAutoresizingMaskIntoConstraints = false
        bubbleTailImageView.translatesAutoresizingMaskIntoConstraints = false

        let maskView = UIView(frame: bounds)
        maskView.addSubview(bubbleImageView)
        maskView.addSubview(bubbleTailImageView)
        self.maskView = maskView

        backgroundColor = UIColor.clearColor()
        contentView.backgroundColor = UIColor.clearColor()
        isShowingBubbleTail = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        maskView?.frame = contentView.frame
    }

    func layoutBubbleTailImageView() {
        var rect = bubbleImageView.frame
        rect.origin.x = rect.maxX - 16
        rect.origin.y = rect.maxY - 21
        rect.size = bubbleTailImageView.image?.size ?? CGSizeZero
        bubbleTailImageView.frame = rect
    }
}
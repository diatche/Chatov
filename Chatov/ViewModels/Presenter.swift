//
//  Presenter.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 5/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import Foundation

class Presenter {
    static let sharedInstance = Presenter()

    func sendTextMessage(text: String) {
        let message = Message()
        message.text = text
        Manager.sharedInstance.sendMessage(message)
    }
}
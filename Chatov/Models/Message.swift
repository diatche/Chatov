//
//  Message.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 5/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import Foundation
import ObjectMapper

class Message : Mappable {
    var text = ""

    init() {}
    required init?(_ map: Map) {}

    func mapping(map: Map) {
        text <- map["text"]
    }
}
//
//  Message.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 5/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import Foundation
import ObjectMapper
import RxSwift
import MapKit

class Message : NSObject, Mappable, MKAnnotation {
    var text = ""

    var imageUrl: String?
    var image: Variable<UIImage?>?

    @objc var coordinate = kCLLocationCoordinate2DInvalid
    var coordinateIsValid : Bool {
        return CLLocationCoordinate2DIsValid(coordinate)
    }

    override init() {}
    required init?(_ map: Map) {}

    func mapping(map: Map) {
        text <- map["text"]
        imageUrl <- map["imageUrl"]
        coordinate.latitude <- map["latitude"]
        coordinate.longitude <- map["longitude"]
    }
}
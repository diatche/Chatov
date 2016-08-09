//
//  Presenter.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 5/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

class Presenter {
    static let sharedInstance = Presenter()
    private static let locationManager = CLLocationManager()
    private static var locationQueueCount = 0
    let disposeBag = DisposeBag()

    func sendTextMessage(text: String) {
        let message = Message()
        message.text = text
        MessageManager.sharedInstance.sendMessage(message)
    }

    func sendGeoLocation() {
        _ = LocationManager.sharedInstance.getGeoLocation().take(1).subscribeNext { location in
            self.sendGeoLocation(location)
        }
    }

    private func sendGeoLocation(location: CLLocation) {
        let message = Message()
        message.coordinate = location.coordinate
        MessageManager.sharedInstance.sendMessage(message)
    }

    func sendImage(image: UIImage) {
        let message = Message()
        message.image = Variable<UIImage?>(image)
        MessageManager.sharedInstance.sendMessage(message)
    }

    func receiveImageInMessage(message: Message) -> Observable<UIImage> {
        if message.image == nil {
            message.image = Variable<UIImage?>(nil)
            _ = MessageManager.sharedInstance.downloadImage(message.imageUrl!).retry(3).subscribeNext { image in
                message.image!.value = image
            }
        }
        return message.image!
            .asObservable()
            .filter { $0 != nil }
            .map { $0! }
    }
}
//
//  LocationManager.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 8/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

class LocationManager {

    static let sharedInstance = LocationManager()

    private lazy var locationManager : CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        return locationManager
    }()

    private let disposeBag = DisposeBag()

    func getGeoLocation() -> Observable<CLLocation> {
        locationManager.startUpdatingLocation()

        var stream = locationManager.rx_didUpdateLocations.map { locations in
            return locations.last!
        }
        if let currentLocation = locationManager.location {
            stream = stream.startWith(currentLocation)
        }
        stream = stream.filter { location -> Bool in
            return location.horizontalAccuracy >= 0 && location.horizontalAccuracy < kCLLocationAccuracyNearestTenMeters
        }
        .map {
            self.locationManager.stopUpdatingLocation()
            return $0
        }
        return stream
    }
}
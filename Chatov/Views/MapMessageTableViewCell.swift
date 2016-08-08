//
//  MapMessageTableViewCell.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 8/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import UIKit
import MapKit

class MapMessageTableViewCell : MessageTableViewCell {

    @IBOutlet weak var mapView : MKMapView!

    var annotation : MKAnnotation? {
        didSet {
            mapView.removeAnnotations(mapView.annotations)
            if let annotation = self.annotation {
                mapView.showAnnotations([annotation], animated: false)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutMaskWithContentFrame(UIEdgeInsetsInsetRect(mapView.frame, UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
    }
}

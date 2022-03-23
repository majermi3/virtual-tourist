//
//  Pin+Extension.swift
//  VirtualTourist
//
//  Created by Michal Majernik on 3/23/22.
//

import Foundation
import MapKit

extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        uuid = UUID()
    }
}

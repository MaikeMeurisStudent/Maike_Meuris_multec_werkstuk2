//
//  MyAnnatation.swift
//  demo_map
//
//  Created by Johan van den Broek on 15/03/2018.
//  Copyright © 2018 Johan van den Broek. All rights reserved.
//

import Foundation
import MapKit

class MyAnnotation: NSObject, MKAnnotation{
    var coordinate: CLLocationCoordinate2D
    var title: String?
    
    init(coordinate: CLLocationCoordinate2D, title:String?) {
        self.coordinate = coordinate
        self.title = title
        
    }
}



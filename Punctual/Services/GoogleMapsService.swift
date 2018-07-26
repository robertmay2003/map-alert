//
//  GoogleMapsService.swift
//  Punctual
//
//  Created by Robert May on 7/23/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import GoogleMaps
import GooglePlaces

struct GoogleMapsService {
    static func getAddress(at coordinate: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
        let geocoder = GMSGeocoder()
        
        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            guard let address = response?.firstResult(), let lines = address.lines else {
                return
            }
            
            completion(lines.joined(separator: " "))
        }
    }
    
}


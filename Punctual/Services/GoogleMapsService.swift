//
//  GoogleMapsService.swift
//  Punctual
//
//  Created by Robert May on 7/23/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import GoogleMaps
import GooglePlaces
import Alamofire
import SwiftyJSON

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
    
    static func getRoute(from origin: (latitude: CLLocationDegrees, longitude: CLLocationDegrees), to destination: (latitude: CLLocationDegrees, longitude: CLLocationDegrees), withTransport travelType: String, leavingAt date: TimeInterval? = nil, completion: @escaping (JSON?) -> Void) {
        var dateForRequest = ""
        if let date = date {
            dateForRequest = String(Int(date))
        } else {
            dateForRequest = "now"
        }
        let request = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin.latitude),\(origin.longitude)&destination=\(destination.latitude),\(destination.longitude)&mode=\(travelType)&departure_time=\(dateForRequest)&key=AIzaSyDrBVdxezWqWJJLDbFZZpDHAjwc-kLMGqA"
        Alamofire.request(request).response { response in
            if let responseData = response.data {
                let data = Data(responseData)
                guard let json = try? JSON(data: data) else {
                    print("Could not create JSON")
                    print("request:", request)
                    completion(nil)
                    return
                }
                let routes = json["routes"].arrayValue
                if routes.count > 0 {
                    completion(routes[0])
                    return
                } else {
                    print("Google Maps found 0 routes: \(routes)")
                    print("request:", request)
                    completion(nil)
                    return
                }
            }
            print("No response data")
            print("request:", request)
            completion(nil)
            return
        }
    }
}


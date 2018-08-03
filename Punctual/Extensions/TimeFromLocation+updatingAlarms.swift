//
//  TimeFromLocation+updatingAlarms.swift
//  Punctual
//
//  Created by Robert May on 8/1/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation
import GoogleMaps
import GooglePlaces
import UserNotifications

extension TimeFromLocation {
    
    static func checkAlarms(_ currentLocation: CLLocationCoordinate2D?) {
        print("checking alarms")
        for alarm in CoreDataHelper.retrieveAlarms() {
            if let timeFromLocation = alarm as? TimeFromLocation, timeFromLocation.updating {
                print("Checking alarm \(alarm.title ?? "untitled")")
                timeFromLocation.setNotification(currentOrigin: currentLocation)
            }
        }
    }
}

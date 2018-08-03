//
//  TimFromLocation+setNotification.swift
//  Punctual
//
//  Created by Robert May on 8/1/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation
import UserNotifications
import GoogleMaps
import GooglePlaces
import SwiftyJSON

extension TimeFromLocation {
    
    func setNotification(currentOrigin: CLLocationCoordinate2D?) {
        let center = UNUserNotificationCenter.current()
        let identifier = String(id)
        if !active {
            center.removePendingNotificationRequests(withIdentifiers: getIdentifiers())
            return
        }
        for i in 0...Int(notificationRepeats) {
            let content = UNMutableNotificationContent()
            guard let title = title,
                let message = notificationMessage,
                let transportation = transportation
                else { return }
            content.title = title
            content.body = message
            content.userInfo = ["alarm": asDict()]
            content.sound = UNNotificationSound.default()
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let today = formatter.string(from: Date())
            var triggerDate: DateComponents!
            var time: Int?
            let departureTime = Date().addingTimeInterval(margin).timeIntervalSince1970
            
            var origin: CLLocationCoordinate2D!
            if useLocation {
                guard let currentOrigin = currentOrigin else { return }
                origin = currentOrigin
            } else {
                origin = CLLocationCoordinate2D(latitude: originLatitude, longitude: originLongitude)
            }
            
            GoogleMapsService.getRoute(from: (origin.latitude, origin.longitude), to: (latitude, longitude), withTransport: transportation, leavingAt: departureTime) { route in
                guard let route = route else { return }
                time = route["legs"][0][transportation == "driving" ? "duration_in_traffic" : "duration"]["value"].intValue
            }
            guard let commuteTime = time else { return }
            if daily {
                // Check if alarm was already activated today
                if let dateShown = dateShown, formatter.string(from: dateShown) == today {
                    // Do nothing
                } else {
                    if let eventTime = eventTime {
                        if eventTime.addingTimeInterval(TimeInterval(-commuteTime)).timeIntervalSince1970 <= departureTime {
                            triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: Date())
                        }
                    }
                }
            } else {
                // Check if alarm was already activated at all
                if dateShown == nil {
                    if let eventTime = eventTime {
                        if eventTime.addingTimeInterval(TimeInterval(-commuteTime)).timeIntervalSince1970 <= departureTime {
                            triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: Date())
                        }
                    }
                }
            }
            // Add thirty seconds for each repeated notification
            triggerDate.second = i * 30
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                        repeats: false)
            let request = UNNotificationRequest(identifier: identifier + String(i),
                                                content: content, trigger: trigger)
            
            center.add(request, withCompletionHandler: { (error) in
                if let error = error {
                    print("Notification error: \(error.localizedDescription)")
                }
            })
        }
    }
}

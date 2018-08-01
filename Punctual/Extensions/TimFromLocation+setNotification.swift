//
//  TimFromLocation+setNotification.swift
//  Punctual
//
//  Created by Robert May on 8/1/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation
import UserNotifications
import SwiftyJSON

extension TimeFromLocation {
    
    func setNotification() {
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
                let margin = margin
                else { return }
            content.title = title
            content.body = message
            content.userInfo = ["alarm": asDict()]
            content.sound = UNNotificationSound.default()
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let today = formatter.string(from: Date())
            let alarms = CoreDataHelper.retrieveAlarms()
            var triggerDate: DateComponents!
            var time: Date?
            let departureTime = Date().addingTimeInterval(margin).timeIntervalSince1970
            
            GoogleMapsService.getRoute(from: (originLatitude, originLongitude), to: (latitude, longitude), withTransport: transportation, leavingAt: departureTime) { route in
                guard let route = route else { return }
                time = route["legs"][0][transportation == "driving" ? "duration_in_traffic" : "duration"]["value"].intValue
            }
            guard let commuteTime = time else { return }
            if daily {
                // Check if alarm was already activated today
                if formatter.string(from: dateShown) != today {
                    if eventTime.addingTimeInterval(-commuteTime) <= departureTime {
                        triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: Date())
                    }
                }
            } else {
                // Check if alarm was already activated at all
                if dateShown == nil {
                    if eventTime.addingTimeInterval(-commuteTime) <= departureTime {
                        triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: Date())
                    }
                }
            }
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

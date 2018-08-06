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
        print("Checking alarm \(String(describing:title))")
        let center = UNUserNotificationCenter.current()
        let identifier = String(id)
        if !active {
            print("Ending check: inactive")
            center.removePendingNotificationRequests(withIdentifiers: getIdentifiers())
            return
        }
        for i in 0...Int(notificationRepeats) {
            let content = UNMutableNotificationContent()
            guard let title = title,
                let message = notificationMessage,
                let transportation = transportation
                else {
                    print("Ending check: bad transportation or notification message")
                    return
            }
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
                guard let route = route else {
                    print("Ending check: no route")
                    return
                }
                time = route["legs"][0][transportation == "driving" ? "duration_in_traffic" : "duration"]["value"].intValue
                guard let commuteTime = time else {
                    print("Ending check: time was not set")
                    return
                }
                if self.daily {
                    // Check if alarm was already activated today
                    if let dateShown = self.dateShown, formatter.string(from: dateShown) == today {
                        print("Ending check: shown today")
                        return
                    } else {
                        if var eventTime = self.eventTime {
                            // set day of event time to today
                            var eventTimeComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second,], from: eventTime)
                            let todayComponents = Calendar.current.dateComponents([.year, .month, .day,], from: Date())
                            eventTimeComponents.year = todayComponents.year
                            eventTimeComponents.month = todayComponents.month
                            eventTimeComponents.day = todayComponents.day
                            if let newDate = Calendar.current.date(from: eventTimeComponents) {
                                eventTime = newDate
                            } else {
                                print("Ending check: bad newDate")
                            }
                            
                            if eventTime.addingTimeInterval(TimeInterval(-commuteTime)).timeIntervalSince1970 <= departureTime {
                                if eventTime.timeIntervalSince1970 <= departureTime {
                                    print("Ending check: alarm was should have been activated too long ago")
                                    return
                                }
                                print("Time is decided: Now")
                                triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: Date())
                                // If the time that you must recieve the notification is greater than 5 minutes away, set it anyway; if it is later updated, it will be overwritten to a better time (improves accuracy with 5 minute updates)
                            } else {
                                print("Time is decided: a few minutes away")
                                triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: Date().addingTimeInterval(eventTime.addingTimeInterval(TimeInterval(-commuteTime)).timeIntervalSince1970 - departureTime))
                            }
                        } else {
                            print("Ending check: no eventTime")
                            return
                        }
                    }
                } else {
                    // Check if alarm was already activated at all
                    if self.dateShown == nil {
                        if let eventTime = self.eventTime {
                            // If the time that you must recieve the notification is less than 5 or equal to minutes away, send notification now
                            if eventTime.addingTimeInterval(TimeInterval(-commuteTime)).timeIntervalSince1970 <= departureTime {
                                if eventTime.timeIntervalSince1970 <= departureTime {
                                    print("Ending check: alarm was should have been activated too long ago")
                                    return
                                }
                                print("Time is decided: Now")
                                triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: Date())
                                // If the time that you must recieve the notification is greater than 5 minutes away, set it anyway; if it is later updated, it will be overwritten to a better time (improves accuracy with 5 minute updates)
                            } else {
                                print("Time is decided: more than 5 minutes away")
                                triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: Date().addingTimeInterval(eventTime.addingTimeInterval(TimeInterval(-commuteTime)).timeIntervalSince1970 - departureTime))
                            }
                            print("Required departure time: \(eventTime.addingTimeInterval(TimeInterval(-commuteTime)))")
                            print("Desired departure time: \(Date(timeIntervalSince1970: departureTime))")
                        } else {
                            print("Ending check: no eventTime")
                            return
                        }
                    } else {
                        print("Ending check: non-daily alarm was already activated")
                        return
                    }
                }
                // Add thirty seconds for each repeated notification
                if let seconds = triggerDate.second {
                    triggerDate.second = seconds + i * 30 + 1
                } else {
                    triggerDate.second = i * 30 + 1
                }
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                            repeats: false)
                let request = UNNotificationRequest(identifier: identifier + String(i),
                                                    content: content, trigger: trigger)
                
                center.add(request, withCompletionHandler: { (error) in
                    if let error = error {
                        print("Notification error: \(error.localizedDescription)")
                    }
                })
                print("Notification added")
            }
        }
    }
}

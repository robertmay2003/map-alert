//
//  SetTime+setNotification.swift
//  Punctual
//
//  Created by Robert May on 7/31/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation
import UserNotifications

extension SetTime {
    
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
                let alarmTime = alarmTime
                else { return }
            content.title = title
            content.body = message
            content.userInfo = ["alarm": asDict()]
            content.sound = UNNotificationSound.default()
            
            var triggerDate: DateComponents!
            if daily {
                triggerDate = Calendar.current.dateComponents([.hour,.minute,.second,], from: alarmTime)
            } else {
                triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: alarmTime)
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


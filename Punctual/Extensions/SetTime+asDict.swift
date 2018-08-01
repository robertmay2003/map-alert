//
//  SetTime+asDict.swift
//  Punctual
//
//  Created by Robert May on 7/30/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation

extension SetTime {
    func asDict() -> [String: Any] {
        return [
            "type": "ST",
            "title": title ?? "Untitled",
            "longitude": longitude,
            "latitude": latitude,
            "eventTime": eventTime ?? Date(),
            "alarmTime": alarmTime ?? Date(),
            "transportation": transportation ?? "walk",
            "reps": notificationRepeats,
            "id": id
        ]
    }
}

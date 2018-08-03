//
//  TimeFromLocation+asDict.swift
//  Punctual
//
//  Created by Robert May on 8/1/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation

extension TimeFromLocation {
    func asDict() -> [String: Any] {
        return [
            "type": "TFL",
            "title": title ?? "Untitled",
            "useLocation": useLocation,
            "longitude": longitude,
            "latitude": latitude,
            "originLongitude": originLongitude,
            "originLatitude": originLatitude,
            "eventTime": eventTime ?? Date(),
            "margin": margin,
            "daily": daily,
            "transportation": transportation ?? "walk",
            "reps": notificationRepeats,
            "id": id
        ]
    }
}

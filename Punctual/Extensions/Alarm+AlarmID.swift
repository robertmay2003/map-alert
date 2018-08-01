//
//  Alarm+AlarmID.swift
//  Punctual
//
//  Created by Robert May on 7/27/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation

extension Alarm {
    static var currentAlarm = 0
    
    static func fetchId() -> Int {
        currentAlarm += 1
        return currentAlarm
    }
    
    func getIdentifiers() -> [String] {
        var arr = [String]()
        for i in 0...4 {
            arr.append(String(id) + String(i))
        }
        return arr
    }
    
    static func getIdentifiers(for id: Int64) -> [String] {
        var arr = [String]()
        for i in 0...4 {
            arr.append(String(id) + String(i))
        }
        return arr
    }
}

//
//  CoreDataHelper.swift
//  Punctual
//
//  Created by Robert May on 7/23/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation
import UIKit
import CoreData

struct CoreDataHelper {
    static let context: NSManagedObjectContext = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError()
        }

        let persistentContainer = appDelegate.persistentContainer
        let context = persistentContainer.viewContext

        return context
    }()

    static func newSTAlarm() -> SetTime {
        let alrm = NSEntityDescription.insertNewObject(forEntityName: "SetTime", into: context) as! SetTime

        return alrm
    }
    
    static func newTFLAlarm() -> TimeFromLocation {
        let alrm = NSEntityDescription.insertNewObject(forEntityName: "TimeFromLocation", into: context) as! TimeFromLocation
        
        return alrm
    }

    static func saveAlarms() {
        do {
            try context.save()
        } catch let error {
            print("Could not save \(error.localizedDescription)")
        }
    }

    static func delete(alarm: Alarm, completion: @escaping () -> Void) {
        context.delete(alarm)

        saveAlarms()
        completion()
    }

    static func retrieveAlarms() -> [Alarm] {
        do {
            let fetchRequest = NSFetchRequest<Alarm>(entityName: "Alarm")
            let results = try context.fetch(fetchRequest)

            return results.reversed()
        } catch let error {
            print("Could not fetch \(error.localizedDescription)")

            return []
        }
    }

    static func reset(notes: [Alarm]) {
        for note in notes {
            context.delete(note)
        }
    }
    
    static func alarmWasShown(with id: Int64) {
        for alarm in retrieveAlarms() {
            if alarm.id == id {
                alarm.dateShown = Date()
            }
        }
        saveAlarms()
    }
    
    static func retrieveAlarm(with id: Int64) -> Alarm? {
        for alarm in retrieveAlarms() {
            if alarm.id == id {
                return alarm
            }
        }
        return nil
    }
}

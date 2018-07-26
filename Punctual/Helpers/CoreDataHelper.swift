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

        print("did something with core data")
        return context
    }()

    static func newSTAlarm() -> SetTime {
        let alrm = NSEntityDescription.insertNewObject(forEntityName: "SetTime", into: context) as! SetTime

        print("did something with core data")
        return alrm
    }

    static func saveAlarms() {
        do {
            try context.save()
        } catch let error {
            print("Could not save \(error.localizedDescription)")
        }
        print("did something with core data")
    }

    static func delete(note: Alarm) {
        context.delete(note)

        saveAlarms()
        print("did something with core data")
    }

    static func retrieveAlarms() -> [Alarm] {
        print("did something with core data")
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
        print("did something with core data")
        for note in notes {
            context.delete(note)
        }
    }
}

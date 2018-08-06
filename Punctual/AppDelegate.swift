//
//  AppDelegate.swift
//  Punctual
//
//  Created by Robert May on 7/23/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import UIKit
import CoreData
import GoogleMaps
import GooglePlaces
import UserNotifications
import Firebase
import AudioToolbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate, MessagingDelegate {

    var window: UIWindow?
    var ringingAlarm: Alarm?
    let locationManager = CLLocationManager()
    weak var timer: Timer?
    fileprivate var fetchRequest: URLRequest? {
        // create this however appropriate for your app
        guard let url = URL(string: "https://www.google.com/") else { return nil }
        let request: URLRequest = URLRequest(url: url)
        return request
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyDrBVdxezWqWJJLDbFZZpDHAjwc-kLMGqA")
        GMSPlacesClient.provideAPIKey("AIzaSyDrBVdxezWqWJJLDbFZZpDHAjwc-kLMGqA")
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let options: UNAuthorizationOptions = [.alert, .badge, .sound];
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Something went wrong")
            }
        }
        
        application.registerForRemoteNotifications()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        timer?.invalidate()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        timer?.invalidate()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        // Update TimeFromLocation alarms every 1 minute while Punctual is running
        TimeFromLocation.checkAlarms(locationManager.location?.coordinate)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            if let appDelegate = self {
                TimeFromLocation.checkAlarms(appDelegate.locationManager.location?.coordinate)
            }
        }
        
        ringingAlarm = getMostRecentAlarm()
        if let current = ringingAlarm {
            if let setTime = current as? SetTime {
                showAlarm(alarm: setTime.asDict())
            } else {
                // No implementaion here yet
            }
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        timer?.invalidate()
    }

    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Punctual")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // When a notification is recieved while app is open
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification recieved")
        //Handle the notification
        
        if let alarm = notification.request.content.userInfo["alarm"] as? [String: Any] {
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate), nil)
            showAlarm(alarm: alarm)
        }
    }
    
    // When a notification is tapped
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //Handle the notification
        if let alarm = response.notification.request.content.userInfo["alarm"] as? [String: Any] {
            if let type = alarm["type"] as? String {
                if type == "ST" {
                    showAlarm(alarm: alarm)
                } else {
                    // no implementation yet
                }
            }
        }
        completionHandler()
        
    }
    
    func getMostRecentAlarm() -> Alarm? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let alarms = CoreDataHelper.retrieveAlarms()
        if alarms.count > 0 {
            var mostRecent = alarms[0]
            for alarm in alarms[1..<alarms.count] {
                if let alarmEvent = alarm.eventTime,
                    let recentEvent = mostRecent.eventTime {
                    if alarmEvent > recentEvent && alarmEvent < Date() {
                        if let dateShown = alarm.dateShown {
                            if (alarm.daily && formatter.string(from: dateShown) != today) {
                                mostRecent = alarm
                            }
                        } else {
                            if (!alarm.daily && alarm.dateShown == nil && alarm.active) {
                                mostRecent = alarm
                            }
                        }
                    }
                }
            }
            if let dateShown = mostRecent.dateShown {
                if (mostRecent.daily && formatter.string(from: dateShown) != today) && mostRecent.active {
                    return mostRecent
                } else {
                    return nil
                }
            } else if (!mostRecent.daily && mostRecent.dateShown == nil) && mostRecent.active {
                return mostRecent
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private func showAlarm(alarm: [String: Any]) {
        let storyboard = UIStoryboard(name: "DisplayAlarm", bundle: .main)
        if let initialViewController = storyboard.instantiateInitialViewController() as? DisplayAlarmViewController {
            initialViewController.alarm = alarm
            initialViewController.delegate = self
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("fcm token:", fcmToken)
        Messaging.messaging().subscribe(toTopic: "all")
    }
}

extension AppDelegate: DisplayAlarmViewControllerDelegate {
    
    func toMainScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        if let initialViewController = storyboard.instantiateInitialViewController() as? UINavigationController {
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }
    }
}


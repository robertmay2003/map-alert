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
import Firebase
import FirebaseDatabase
import FirebaseInstanceID
import FirebaseMessaging
import UserNotifications
import AudioToolbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate{

    var window: UIWindow?
    var ringingAlarm: Alarm?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyDrBVdxezWqWJJLDbFZZpDHAjwc-kLMGqA")
        GMSPlacesClient.provideAPIKey("AIzaSyDrBVdxezWqWJJLDbFZZpDHAjwc-kLMGqA")

        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM
            Messaging.messaging().delegate = self
            UNUserNotificationCenter.current().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        FirebaseApp.configure()
        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instange ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        ringingAlarm = getMostRecentAlarm()
        if let current = ringingAlarm {
            if let setTime = current as? SetTime {
                showSetTime(alarm: setTime.asDict())
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
    
    func applicationReceivedRemoteMessage(_ remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        let emptyUser = [fcmToken: ["initiated": true]]
        Database.database().reference().updateChildValues(emptyUser)
        
        let dataDict:[String: Any] = [
            "token": fcmToken,
            "currentAlarms": []
        ]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    // When a notification is recieved while app is open
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //Handle the notification
        //This will get the text sent in your notification
        
        //This works for iphone 7 and above using haptic feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
        
        //This works for all devices. Choose one or the other.
        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate), nil)
        
        if let alarm = notification.request.content.userInfo["alarm"] as? [String: Any] {
            showSetTime(alarm: alarm)
        }
    }
    
    // When a notification is tapped
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //Handle the notification
        print("did receive")
        let body = response.notification.request.content.body
        if let alarm = response.notification.request.content.userInfo["alarm"] as? [String: Any] {
            if let type = alarm["type"] as? String {
                if type == "ST" {
                    showSetTime(alarm: alarm)
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
                print("comparing alarm \(alarm.title) to alarm \(mostRecent.title!)")
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
    
    private func showSetTime(alarm: [String: Any]) {
        print("peanut butter jelly time")
        let storyboard = UIStoryboard(name: "SetTimeDisplay", bundle: .main)
        if let initialViewController = storyboard.instantiateInitialViewController() as? DisplaySetTimeAlarmViewController {
            initialViewController.alarm = alarm
            initialViewController.delegate = self
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }
    }
}

extension AppDelegate: DisplaySetTimeAlarmViewControllerDelegate {
    
    func toMainScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        if let initialViewController = storyboard.instantiateInitialViewController() as? UINavigationController {
            print("leaving alarm view")
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }
    }
}


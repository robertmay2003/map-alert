//
//  DisplaySetTimeAlarmViewController.swift
//  Punctual
//
//  Created by Robert May on 7/30/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import UserNotifications

class DisplaySetTimeAlarmViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var arrivalTimeLabel: UILabel!
    @IBOutlet weak var preparationTimeLabel: UILabel!
    @IBOutlet weak var commuteTimeLabel: UILabel!
    
    @IBOutlet weak var snoozeButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    
    @IBOutlet weak var mapView: GMSMapView!
    
    var alarm: [String: Any]!
    let locationManager = CLLocationManager()
    let center = UNUserNotificationCenter.current()
    weak var timer: Timer?
    weak var delegate: DisplaySetTimeAlarmViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        if let id = alarm["id"] as? Int64 {
            center.removePendingNotificationRequests(withIdentifiers: Alarm.getIdentifiers(for: id))
        }
        configure()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configure() {
        titleLabel.text = alarm["title"] as? String
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd HH:mm"
        if let event = alarm["eventTime"] as? Date {
            arrivalTimeLabel.text = formatter.string(from: event)
        }
        
        if let latitude = alarm["latitude"] as? CLLocationDegrees,
            let longitude = alarm["longitude"] as? CLLocationDegrees {
            let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 15)
            mapView.camera = camera
            
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            GoogleMapsService.getAddress(at: marker.position) { (address) in
                marker.title = address
            }
            marker.map = mapView
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let origin: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        if let latitude = alarm["latitude"] as? CLLocationDegrees,
            let longitude = alarm["longitude"] as? CLLocationDegrees,
            let transportation = alarm["transportation"] as? String {
            GoogleMapsService.getRoute(from: (origin.latitude, origin.longitude), to: (latitude, longitude), withTransport: transportation) { route in
                guard let route = route else { return }
                let routeOverviewPolyline = route["overview_polyline"].dictionary
                let points = routeOverviewPolyline?["points"]?.stringValue
                let path = GMSPath.init(fromEncodedPath: points!)
                let polyline = GMSPolyline.init(path: path)
                polyline.strokeColor = UIColor(red: 0, green: 0.4784, blue: 1, alpha: 1.0)
                polyline.strokeWidth = 4
                polyline.map = self.mapView
                let time = route["legs"][0][transportation == "driving" ? "duration_in_traffic" : "duration"]["value"].intValue

                self.timer?.invalidate()
                // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
                self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    self?.updateTimeLabels(commuteTime: time)
                }
            }
        }
        locationManager.stopUpdatingLocation()
    }
    
    func updateTimeLabels(commuteTime: Int) {
        guard let eventTime = alarm["eventTime"] as? Date else { return }
        // Get time left until event
        let timeLeft = eventTime.timeIntervalSince(Date())
        
        // Set up date formatter
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        
        // Get commute time
        let interval = Int(timeLeft) < commuteTime ? (Int(timeLeft) <= 0 ? 0 : Int(timeLeft)) : commuteTime
        
        if let commuteTime = formatter.string(from: TimeInterval(interval)) {
            commuteTimeLabel.text = commuteTime
        }
        
        // Get time until commute
        let timeUntilCommute = Int(timeLeft) - commuteTime > 0 ? Int(timeLeft) - commuteTime : 0
        
        if let preparationTime = formatter.string(from: TimeInterval(timeUntilCommute)) {
            preparationTimeLabel.text = preparationTime
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    deinit {
        stopTimer()
    }
    
    @IBAction func dismissPressed(_ sender: UIButton) {
        stopTimer()
        delegate?.toMainScreen()
        guard let id = alarm["id"] as? Int64 else {
            print("Invalid alarm with id: \(alarm["id"] ?? "nil")")
            return
        }
        CoreDataHelper.alarmWasShown(with: id)
    }
    
    @IBAction func snoozePressed(_ sender: UIButton) {
        guard let id = alarm["id"] as? Int64 else {
            print("Invalid alarm with id: \(alarm["id"] ?? "nil")")
            return
        }
        if let alarm = CoreDataHelper.retrieveAlarm(with: id) as? SetTime {
            // alarm.alarmTime = Date().addingTimeInterval(5.0 * 60.0)
            alarm.alarmTime = Date().addingTimeInterval(60.0)
            alarm.setNotification()
            alarm.alarmTime = Date().addingTimeInterval(-60.0)
            CoreDataHelper.alarmWasShown(with: id)
        }
        CoreDataHelper.saveAlarms()
        stopTimer()
        delegate?.toMainScreen()
    }
}

protocol DisplaySetTimeAlarmViewControllerDelegate: class {
    func toMainScreen() -> Void
}

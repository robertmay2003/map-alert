//
//  EditSetTimeAlarmViewController.swift
//  Punctual
//
//  Created by Robert May on 7/24/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import UserNotifications

class EditSetTimeAlarmViewController: UIViewController {
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var activeSwitch: UISwitch!
    @IBOutlet weak var activeStatusLabel: UILabel!
    
    @IBOutlet weak var locationMapView: GMSMapView!
    @IBOutlet weak var addressTextField: UITextField!
    
    @IBOutlet weak var arrivalTimeDatePicker: UIDatePicker!
    @IBOutlet weak var alarmTimeDatePicker: UIDatePicker!
    
    @IBOutlet weak var transportSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var dailySwitch: UISwitch!
    @IBOutlet weak var repetitionsTextField: UITextField!
    @IBOutlet weak var customMessageTextField: UITextView!
    
    let locationManager = CLLocationManager()
    var mapMarker = GMSMarker()
    var alarm: SetTime?
    let center = UNUserNotificationCenter.current()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if alarm == nil {
            locationMapView?.isMyLocationEnabled = true
            locationMapView.settings.myLocationButton = true
            
        
            //Location Manager code to fetch current location
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
        
        locationMapView.delegate = self
        
        mapMarker.map = self.locationMapView
        
        // Set up alarm if editing
        if let alarm = alarm {
            titleTextField.text = alarm.title
            customMessageTextField.text = alarm.notificationMessage
            repetitionsTextField.text = String(alarm.notificationRepeats)
            activeStatusLabel.text = alarm.active ? "Active" : "Inactive"
            
            if let eventTime = alarm.eventTime,
                let alarmTime = alarm.alarmTime {
                alarmTimeDatePicker.date = alarmTime
                arrivalTimeDatePicker.date = eventTime
            }
            
            activeSwitch.isOn = alarm.active
            dailySwitch.isOn = alarm.daily
            
            if let index = ["driving", "bicycling", "walking"].index(of: alarm.transportation) {
                transportSegmentedControl.selectedSegmentIndex = Int(index)
            }
            
            let coordinate = CLLocationCoordinate2D(latitude: alarm.latitude, longitude: alarm.longitude)
            
            reverseGeocodeCoordinate(coordinate)
            locationMapView.camera = GMSCameraPosition(target: coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        }
        
        // Set keyboard hiding
        setupKeyboard()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchPressed(_ sender: UISwitch) {
        activeStatusLabel.text = activeSwitch.isOn ? "Active" : "Inactive"
    }
    
    func saveAlarm() -> Bool {
        guard let title = titleTextField.text else {
            print("unexpected nil in title")
            return false
        }
        let spaceCount = title.components(separatedBy: " ").count - 1
        if spaceCount == title.count {
            titleTextField.text = ""
            titleTextField.placeholder = "Please enter a title."
            return false
        }
        let active = activeSwitch.isOn
        let daily = dailySwitch.isOn
        var repetitions = ""
        if let reps2 = repetitionsTextField.text {
            let spaceCount = reps2.components(separatedBy: " ").count - 1
            if spaceCount == reps2.count {
                repetitionsTextField.text = ""
                repetitions = "0"
                return false
            } else {
                repetitions = reps2
            }
        }
        guard var reps = Int(repetitions) else {
            print("unexpected nil in reps")
            return false
        }
        if reps > 4 {
            reps = 4
            repetitionsTextField.text = "4"
        }
        let modeOfTransport = ["driving", "bicycling", "walking"][transportSegmentedControl.selectedSegmentIndex]
        var message = ""
        if let customMessage = customMessageTextField.text {
            let spaceCount = customMessage.components(separatedBy: " ").count - 1
            if spaceCount == customMessage.count {
                message = "Your alarm, \(title), is ringing!"
            } else {
                message = customMessage
            }
        }
        let arrivalTime = arrivalTimeDatePicker.date
        let alarmTime = alarmTimeDatePicker.date
        let long = mapMarker.position.longitude
        let lat = mapMarker.position.latitude
        if alarm == nil {
            alarm = CoreDataHelper.newSTAlarm()
            if let alarm = alarm {
                alarm.id = Int64(Alarm.fetchId())
            }
        }
        if let alarm = alarm {
            alarm.title = title
            alarm.alarmTime = alarmTime
            alarm.eventTime = arrivalTime
            alarm.transportation = modeOfTransport
            alarm.daily = daily
            alarm.active = active
            alarm.notificationRepeats = Int32(reps)
            alarm.notificationMessage = message
            alarm.latitude = lat
            alarm.longitude = long
            if alarmTime > Date() {
                alarm.dateShown = nil
            }
    
            CoreDataHelper.saveAlarms()
            
            // Set up notification
            alarm.setNotification()
        }
        return true
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        guard let ident = identifier else {
            return false
        }
        
        switch ident {
        case "save":
            return saveAlarm()
        case "cancel":
            return true
        default:
            print("unexpected segue")
            return false
        }
    }
    
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        GoogleMapsService.getAddress(at: coordinate) { (address) in
            self.addressTextField.text = address
        }
            
        self.mapMarker.position = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

extension EditSetTimeAlarmViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        if alarm == nil {
            locationMapView.isMyLocationEnabled = true
            locationMapView.settings.myLocationButton = true
            
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        locationMapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        locationManager.stopUpdatingLocation()
    }
}

extension EditSetTimeAlarmViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        reverseGeocodeCoordinate(position.target)
    }
}

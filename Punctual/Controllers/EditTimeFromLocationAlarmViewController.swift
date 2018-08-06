//
//  EditTimeFromLocationAlarm.swift
//  Punctual
//
//  Created by Robert May on 8/1/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import GooglePlaces
import UserNotifications

class EditTimeFromLocationAlarmViewController: UIViewController {
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var activeSwitch: UISwitch!
    @IBOutlet weak var activeStatusLabel: UILabel!
    
    @IBOutlet weak var startingLocationMapView: IdentifiedMapView!
    @IBOutlet weak var startingAddressTextField: UILabel!
    @IBOutlet weak var useMyLocationSwitch: UISwitch!
    
    @IBOutlet weak var destinationMapView: IdentifiedMapView!
    @IBOutlet weak var destinationTextField: UILabel!
    
    @IBOutlet weak var arrivalTimeDatePicker: UIDatePicker!
    @IBOutlet weak var marginDatePicker: UIDatePicker!
    
    @IBOutlet weak var transportSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var dailySwitch: UISwitch!
    @IBOutlet weak var repetitionsTextField: UITextField!
    @IBOutlet weak var customMessageTextField: UITextView!
    
    @IBOutlet weak var titleContainerView: UIView!
    @IBOutlet weak var destinationContainerView: UIView!
    @IBOutlet weak var originContainerView: UIView!
    @IBOutlet weak var timeContainerView: UIView!
    @IBOutlet weak var arrivalTimeContainerView: UIView!
    @IBOutlet weak var marginContainerView: UIView!
    @IBOutlet weak var arrivalTimeDatePickerContainerView: UIView!
    @IBOutlet weak var marginDatePickerContainerView: UIView!
    @IBOutlet weak var transportationContainerView: UIView!
    @IBOutlet weak var notificationSettingsContainerView: UIView!
    @IBOutlet weak var innerNotificationSettingsContainerView: UIView!
    @IBOutlet weak var dailyContainerView: UIView!
    @IBOutlet weak var repeatsContainerView: UIView!
    @IBOutlet weak var customMessageContainerView: UIView!
    @IBOutlet weak var saveButton: UIButton!
    
    let startingLocationManager = IdentifiedLocationManager()
    let destinationManager = IdentifiedLocationManager()
    var originMarker = GMSMarker()
    var destinationMarker = GMSMarker()
    var alarm: TimeFromLocation?
    let center = UNUserNotificationCenter.current()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupLayers()
        
        if alarm == nil {
            startingLocationMapView?.isMyLocationEnabled = true
            destinationMapView?.isMyLocationEnabled = true
            startingLocationMapView.settings.myLocationButton = true
            destinationMapView.settings.myLocationButton = true
            
            
            //Location Manager code to fetch current location
            startingLocationManager.delegate = self
            startingLocationManager.startUpdatingLocation()
            
            destinationManager.delegate = self
            destinationManager.startUpdatingLocation()
        }
        
        startingLocationMapView.delegate = self
        destinationMapView.delegate = self
        
        startingLocationMapView.marker = originMarker
        destinationMapView.marker = destinationMarker
        
        originMarker.map = self.startingLocationMapView
        destinationMarker.map = self.destinationMapView
        
        destinationMapView.name = "destination"
        startingLocationMapView.name = "origin"
        
        destinationManager.mapView = destinationMapView
        startingLocationManager.mapView = startingLocationMapView
        
        // Set up alarm if editing
        if let alarm = alarm {
            titleTextField.text = alarm.title
            customMessageTextField.text = alarm.notificationMessage
            repetitionsTextField.text = String(alarm.notificationRepeats)
            activeStatusLabel.text = alarm.active ? "Active" : "Inactive"
            
            if let eventTime = alarm.eventTime {
                marginDatePicker.countDownDuration = alarm.margin
                arrivalTimeDatePicker.date = eventTime
            }
            
            activeSwitch.isOn = alarm.active
            dailySwitch.isOn = alarm.daily
            useMyLocationSwitch.isOn = alarm.useLocation
            
            if let index = ["driving", "bicycling", "walking"].index(of: alarm.transportation) {
                transportSegmentedControl.selectedSegmentIndex = Int(index)
            }
            
            let coordinate = CLLocationCoordinate2D(latitude: alarm.originLatitude, longitude: alarm.originLongitude)
            
            reverseGeocodeCoordinate(coordinate, marker: originMarker, label: startingAddressTextField)
            startingLocationMapView.camera = GMSCameraPosition(target: coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            
            let destinationCoordinate = CLLocationCoordinate2D(latitude: alarm.latitude, longitude: alarm.longitude)
            
            reverseGeocodeCoordinate(destinationCoordinate, marker: destinationMarker, label: destinationTextField)
            destinationMapView.camera = GMSCameraPosition(target: destinationCoordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        }
        
        // Set keyboard hiding
        setupKeyboard()
    }
    
    func setupLayers() {
        titleContainerView.layer.cornerRadius = 4
        destinationContainerView.layer.cornerRadius = 4
        originContainerView.layer.cornerRadius = 4
        timeContainerView.layer.cornerRadius = 4
        transportationContainerView.layer.cornerRadius = 4
        notificationSettingsContainerView.layer.cornerRadius = 4
        innerNotificationSettingsContainerView.layer.cornerRadius = 4
        saveButton.layer.cornerRadius = 4
        
        UIHelper.addShadow(titleContainerView.layer)
        UIHelper.addShadow(saveButton.layer)
        UIHelper.addShadow(notificationSettingsContainerView.layer)
        UIHelper.addShadow(destinationContainerView.layer)
        UIHelper.addShadow(originContainerView.layer)
        
        destinationMapView.layer.cornerRadius = 4
        startingLocationMapView.layer.cornerRadius = 4
        startingAddressTextField.layer.cornerRadius = 4
        destinationTextField.layer.cornerRadius = 4
        arrivalTimeContainerView.layer.cornerRadius = 4
        marginContainerView.layer.cornerRadius = 4
        dailyContainerView.layer.cornerRadius = 4
        repeatsContainerView.layer.cornerRadius = 4
        customMessageContainerView.layer.cornerRadius = 4

        UIHelper.addShadow(arrivalTimeContainerView.layer)
        UIHelper.addShadow(marginContainerView.layer)
        UIHelper.addShadow(dailyContainerView.layer)
        UIHelper.addShadow(repeatsContainerView.layer)
        UIHelper.addShadow(customMessageContainerView.layer)

        customMessageTextField.layer.cornerRadius = 4
        arrivalTimeDatePickerContainerView.layer.cornerRadius = 4
        marginDatePickerContainerView.layer.cornerRadius = 4
        
        notificationSettingsContainerView.layer.borderWidth = 3
        let borderColor = UIColor(displayP3Red: 165/255, green: 204/255, blue: 236/255, alpha: 1)
        notificationSettingsContainerView.layer.borderColor = borderColor.cgColor
        
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
        let useMyLocation = useMyLocationSwitch.isOn
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
        let margin = marginDatePicker.countDownDuration
        let long = destinationMarker.position.longitude
        let lat = destinationMarker.position.latitude
        let originLat = originMarker.position.latitude
        let originLong = originMarker.position.longitude
        if alarm == nil {
            alarm = CoreDataHelper.newTFLAlarm()
            if let alarm = alarm {
                alarm.id = Int64(Alarm.fetchId())
            }
        }
        if let alarm = alarm {
            alarm.title = title
            alarm.margin = margin
            alarm.eventTime = arrivalTime
            alarm.transportation = modeOfTransport
            alarm.daily = daily
            alarm.active = active
            alarm.notificationRepeats = Int32(reps)
            alarm.notificationMessage = message
            alarm.latitude = lat
            alarm.longitude = long
            alarm.useLocation = useMyLocation
            alarm.originLongitude = originLong
            alarm.originLatitude = originLat
            alarm.updating = alarm.active
            
            CoreDataHelper.saveAlarms()
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
    
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D, marker: GMSMarker, label: UILabel) {
        GoogleMapsService.getAddress(at: coordinate) { (address) in
            label.text = address
        }
        
        marker.position = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

extension EditTimeFromLocationAlarmViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard let manager = manager as? IdentifiedLocationManager else { return }
        guard status == .authorizedWhenInUse else {
            return
        }
        if alarm == nil {
            manager.mapView.isMyLocationEnabled = true
            manager.mapView.settings.myLocationButton = true
            
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        guard let manager = manager as? IdentifiedLocationManager else { return }
        
        manager.mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        manager.stopUpdatingLocation()
    }
}

extension EditTimeFromLocationAlarmViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        guard let mapView = mapView as? IdentifiedMapView else { return }
        if let marker = mapView.marker {
            reverseGeocodeCoordinate(position.target, marker: marker, label: mapView.name == "destination" ? destinationTextField : startingAddressTextField)
        }
    }
}

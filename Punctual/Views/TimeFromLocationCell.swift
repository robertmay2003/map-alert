//
//  AlarmsTableViewCell.swift
//  Punctual
//
//  Created by Robert May on 7/23/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import UIKit
import GoogleMaps

class TimeFromLocationCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var activeStatusLabel: UILabel!
    @IBOutlet weak var activeSwitch: UISwitch!
    @IBOutlet weak var addressLabel: UILabel!
    
    
    var alarm: TimeFromLocation?
    
    func configure() {
        // Set up layers
        containerView.layer.cornerRadius = 4
        mapView.layer.cornerRadius = 4
        
        // Set up labels
        guard let alarm = alarm else { return }
        titleLabel.text = alarm.title
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd HH:mm"
        if let eventTime = alarm.eventTime {
            timeLabel.text = "Arrival: " + formatter.string(from: eventTime)
        } else {
            timeLabel.text = "Error fetching event time."
        }
        activeStatusLabel.text = alarm.active ? "On" : "Off"
        activeSwitch.isOn = alarm.active
        
        let camera = GMSCameraPosition.camera(withLatitude: alarm.latitude, longitude: alarm.longitude, zoom: 11)
        mapView.camera = camera
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: alarm.latitude, longitude: alarm.longitude)
        GoogleMapsService.getAddress(at: marker.position) { (address) in
            self.addressLabel.text = address
        }
        marker.map = mapView
    }
    
    @IBAction func activitySwitchChanged(_ sender: UISwitch) {
        guard let alarm = alarm else { return }
        alarm.active = activeSwitch.isOn
        activeStatusLabel.text = alarm.active ? "On" : "Off"
        alarm.updating = alarm.active
        CoreDataHelper.saveAlarms()
    }
}

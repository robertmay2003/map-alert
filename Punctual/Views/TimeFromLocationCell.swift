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
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var activeStatusLabel: UILabel!
    @IBOutlet weak var activeSwitch: UISwitch!
    
}

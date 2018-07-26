//
//  ViewController.swift
//  Punctual
//
//  Created by Robert May on 7/23/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import UIKit
import GoogleMaps

class ListAlarmsViewController: UIViewController {
    @IBOutlet weak var alarmTableView: UITableView!
    
    private let locationManager = CLLocationManager()
    var alarms = [Alarm]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        alarms = CoreDataHelper.retrieveAlarms()
        alarmTableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {return}
        
        switch identifier {
        case "EditSetTimeAlarm":
            guard let indexPath = alarmTableView.indexPathForSelectedRow else { return }
            guard let alarm = alarms[indexPath.row] as? SetTime else {
                print("Unexpected alarm type in SetTime cell")
                return
            }
            let destination = segue.destination as! EditSetTimeAlarmViewController
            destination.alarm = alarm
        default:
            print("Unexpected segue with identifier: \(identifier)")
        }
    }
    
    @IBAction func unwindWithSegue(_ segue: UIStoryboardSegue) {
    }
}

extension ListAlarmsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let alarm = alarms[indexPath.row]
        
        switch String(describing: type(of: alarm)) {
        case "SetTime":
            let cell = tableView.dequeueReusableCell(withIdentifier: "SetTimeCell") as! SetTimeCell
            cell.alarm = alarm as? SetTime
            cell.configure()
            return cell
        default:
            assertionFailure("Unexpected alarm type: \(type(of: alarm))")
            let cell = tableView.dequeueReusableCell(withIdentifier: "SetTimeCell") as! SetTimeCell
            return cell
        }
    }
}

extension ListAlarmsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

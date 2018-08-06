//
//  AlarmTypeSelectionViewController.swift
//  Punctual
//
//  Created by Robert May on 7/23/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import UIKit

class AlarmTypeSelectionViewController: UIViewController {
    @IBOutlet weak var timeFromLocationContainerView: UIView!
    @IBOutlet weak var setTimeContainerView: UIView!
    
    @IBOutlet weak var timeFromLocationTextContainerView: UIView!
    @IBOutlet weak var setTimeTextContainerView: UIView!
    
    @IBOutlet weak var timeFromLocationCreateButton: UIButton!
    @IBOutlet weak var setTimeCreateButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        timeFromLocationContainerView.layer.cornerRadius = 4
        setTimeContainerView.layer.cornerRadius = 4
        
        UIHelper.addShadow(timeFromLocationContainerView.layer)
        UIHelper.addShadow(setTimeContainerView.layer)
        
        timeFromLocationTextContainerView.layer.cornerRadius = 4
        setTimeTextContainerView.layer.cornerRadius = 4
        
        timeFromLocationCreateButton.layer.cornerRadius = 4
        setTimeCreateButton.layer.cornerRadius = 4
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//
//  UIHelper.swift
//  Punctual
//
//  Created by Robert May on 8/6/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation
import UIKit

struct UIHelper {
    static func addShadow(_ layer: CALayer) {
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowOpacity = 0.2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 5
    }
}

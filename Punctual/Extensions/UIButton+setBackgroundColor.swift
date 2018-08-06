//
//  UIButton+setBackgroundColor.swift
//  Punctual
//
//  Created by Robert May on 8/6/18.
//  Copyright © 2018 Robert May. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.2, animations: {
            self.backgroundColor = self.backgroundColor?.withAlphaComponent(0.6)
        })
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.2, animations: {
            self.backgroundColor = self.backgroundColor?.withAlphaComponent(1.0)
        })
    }
}

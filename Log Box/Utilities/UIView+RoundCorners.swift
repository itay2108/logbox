//
//  UIView+RoundCorners.swift
//  Log Box
//
//  Created by itay gervash on 24/05/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit

extension UIView {
    
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
         
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
             let mask = CAShapeLayer()
             mask.path = path.cgPath
             self.layer.mask = mask
    
    }

}

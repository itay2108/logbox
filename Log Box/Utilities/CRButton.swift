//
//  CRButton.swift
//  Log Box
//
//  Created by itay gervash on 10/05/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit

@IBDesignable
class CRButton: UIButton {

    @IBInspectable var cornerRadius: Int = 0 {
        didSet {
            if cornerRadius > 50 {
                cornerRadius = 50
            }
            setCornerRadius()
        }
    }
    
    func setCornerRadius() {
        self.layer.cornerRadius = self.frame.size.height * (CGFloat(cornerRadius) / 100)
        self.layer.masksToBounds = false
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        setCornerRadius()
    }

}

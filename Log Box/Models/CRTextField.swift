//
//  CRTextField.swift
//  Log Box
//
//  Created by itay gervash on 08/05/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit

@IBDesignable
class CRTextField: UITextField {

    
    @IBInspectable var horizontalTextMargin: Int = 12  {
           didSet {
            edgeInsets = UIEdgeInsets(top: 0, left: CGFloat(horizontalTextMargin), bottom: 0, right: CGFloat(horizontalTextMargin))
            self.bounds = textRect(forBounds: self.bounds)
           }
       }
    
    var edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    
    @IBInspectable var cornerRadius: Int = 0 {
        didSet {
            if cornerRadius > 50 {
                cornerRadius = 50
            }
            setCornerRadius()
        }
    }
    
    
    @IBInspectable var borderWidth: Int = 0 {
        didSet {
            self.layer.borderWidth = CGFloat(borderWidth)
        }
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: edgeInsets)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: edgeInsets)
    }
    
    func setCornerRadius() {
        self.layer.cornerRadius = self.frame.size.height * (CGFloat(cornerRadius) / 100)
        self.layer.masksToBounds = true
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        setCornerRadius()
    }
    
    

}

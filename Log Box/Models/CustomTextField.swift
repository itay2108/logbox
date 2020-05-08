//
//  CustomTextField.swift
//  Log Box
//
//  Created by itay gervash on 07/05/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit

@IBDesignable
final class CustomTextField: UITextField {

    @IBInspectable
    var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable
    var strokeColor: UIColor = .black
    
    @IBInspectable
    var strokeWidth: Int = 2
    
    @IBInspectable
    var activeHeadingSize: Int = 9
    
    @IBInspectable
    var errorColor: UIColor = .red
    

    
    // MARK: - Drawing
    
    

}

enum StrokeVisibility {
    case always
    case active
    case error
    case never
}

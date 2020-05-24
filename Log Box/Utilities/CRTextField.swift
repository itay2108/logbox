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
    
//MARK: - Insets

    var padding: UIEdgeInsets {
        get {
            guard self.font != nil else { return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4) }
            
            let insetX = CGFloat(roundf(Float(self.font!.pointSize * 1.5)))
            return UIEdgeInsets(top: 0, left: insetX, bottom: 0, right: insetX)
        }
    }

    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
//MARK: - Corner Radius
    
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
    
//MARK: - Border Settings
    
    @IBInspectable var borderWidth: Int = 0 {
        didSet {
            self.layer.borderWidth = CGFloat(borderWidth)
        }
    }
    
    @IBInspectable var borderColor: UIColor = .clear {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var activeBorderWidth: Int = 2
    @IBInspectable var activeBorderColor: UIColor = .red
    
//MARK: - Floating Label
    
    var floatingLabel: UILabel!
    var floatingLabelHeight: CGFloat = 14
    @IBInspectable var labelColor: UIColor = .blue
    

    
    var floatingLabelBackground: UIColor = UIColor.white.withAlphaComponent(1) {
        didSet {
            self.floatingLabel.backgroundColor = self.floatingLabelBackground
            self.setNeedsDisplay()
        }
    }
    
    var floatingLabelFont: UIFont! = UIFont.systemFont(ofSize: 11, weight: .medium)
    

    @IBInspectable
    var placeHolder: String? {
        didSet {
            self.placeholder = placeHolder
        }
    }
    

    var floatingLabelColor: UIColor!

//MARK: - inits

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setCornerRadius()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setCornerRadius()
        
        self.clipsToBounds = false
        self.placeHolder = (self.placeHolder != nil) ? self.placeHolder : placeholder
        placeholder = self.placeHolder
        self.floatingLabel = UILabel(frame: CGRect.zero)
        
        self.addTarget(self, action: #selector(self.turnOnEditing), for: .editingDidBegin)
        self.addTarget(self, action: #selector(self.turnOffEditing), for: .editingDidEnd)
    }

    @objc func turnOnEditing() {
        self.layer.borderWidth = CGFloat(activeBorderWidth)
        self.layer.borderColor = activeBorderColor.cgColor
        
        //Add floating label
        if self.text == "" {
                self.floatingLabel.textColor = self.labelColor
                self.floatingLabel.font = floatingLabelFont
                self.floatingLabel.text = self.placeHolder ?? ""
                self.floatingLabel.layer.backgroundColor = UIColor.clear.cgColor
            
                self.floatingLabel.translatesAutoresizingMaskIntoConstraints = false
                self.floatingLabel.clipsToBounds = true
                self.floatingLabel.layer.masksToBounds = false
                self.floatingLabel.frame = CGRect(x: 0, y: 0, width: Int(self.frame.size.width), height: Int(floatingLabelFont.pointSize) + 2)
                self.floatingLabel.textAlignment = .left
            
               
                self.addSubview(self.floatingLabel)
            
                self.floatingLabel.bottomAnchor.constraint(equalTo: self.topAnchor, constant: -8).isActive = true
                self.floatingLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: padding.left).isActive = true
                self.placeholder = ""
        }
            self.bringSubviewToFront(self.floatingLabel)
        self.floatingLabel.animate([.fadeIn, .duration(0.12)], completion: nil)
            self.setNeedsDisplay()
    }
    
    @objc func turnOffEditing() {
        self.layer.borderWidth = CGFloat(borderWidth)
        self.layer.borderColor = borderColor.cgColor
        
        if self.text == "" {

            self.floatingLabel.animate([.fadeOut, .duration(0.12)]) {
                self.subviews.forEach{ $0.removeFromSuperview() }
                self.setNeedsDisplay()
            }
            
            self.placeholder = self.placeHolder
        }
    }

}

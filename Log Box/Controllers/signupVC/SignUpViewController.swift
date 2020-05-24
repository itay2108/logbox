//
//  SignUpViewController.swift
//  Log Box
//
//  Created by itay gervash on 23/05/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit

class SignUpViewController: UILogBoxVC, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: CRTextField!
    @IBOutlet weak var passwordTextField: CRTextField!
    @IBOutlet weak var textFieldStackView: UIStackView!
    
    private let def = UserDefaults.standard
    var isSpacingExpanded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        clearNavBarSeparator()
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == passwordTextField && !isSpacingExpanded {
            textFieldStackView.spacing += (passwordTextField.floatingLabelHeight + 2)
            isSpacingExpanded = true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == passwordTextField && textField.text == "" && isSpacingExpanded {
            textFieldStackView.spacing -= (passwordTextField.floatingLabelHeight + 2)
            isSpacingExpanded = false
        }
    }
    
    @IBAction func continueWithAppleBtnPressed(_ sender: UIButton) {
        def.set(true, forKey: "isLoggedIn")
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func createAccountButtonPressed(_ sender: UIButton) {
        //segue to main VC

    }
    
    
}

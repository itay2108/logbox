//
//  SignInViewController.swift
//  Log Box
//
//  Created by itay gervash on 23/05/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit

class SignInViewController: UILogBoxVC, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: CRTextField!
    @IBOutlet weak var passwordTextField: CRTextField!
    @IBOutlet weak var textFieldStackView: UIStackView!
    @IBOutlet weak var signUpBtn: UIButton!
    
    var isSpacingExpanded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        clearNavBarSeparator()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.navigationBar.backgroundColor = .clear
        self.navigationController?.navigationBar.tintColor = .clear
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
    
    @IBAction func signUpBtnPressed(_ sender: Any) {
        //Segue to Signup VC
    }
    
}

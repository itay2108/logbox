//
//  UILogBoxVC.swift
//  Log Box
//
//  Created by itay gervash on 23/05/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit
import AVFoundation

class UILogBoxVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func clearNavBarSeparator() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    func removeMiddleVCsFromStack() {
        let vcStack = self.navigationController?.viewControllers
        self.navigationController?.setViewControllers([vcStack![0], self], animated: true)
    }
    
    func createAudioSessionObject() -> AVAudioSession? {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            return audioSession
        } catch {
            print(error)
            return nil
        }
    }
    
    func defaultAlert(with title: String, message: String?) -> UIAlertController {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.title = title
        
        if let body = message {
            alert.message = body
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (UIAlertAction) in
        }
        alert.addAction(cancelAction)
        
        return alert
    }
    
    func setupHideKeyboardOnTap() {
        self.view.addGestureRecognizer(self.endEditingRecognizer())
        self.navigationController?.navigationBar.addGestureRecognizer(self.endEditingRecognizer())
    }

    /// Dismisses the keyboard from self.view
    private func endEditingRecognizer() -> UIGestureRecognizer {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(self.view.endEditing(_:)))
        tap.cancelsTouchesInView = false
        return tap
    }


}

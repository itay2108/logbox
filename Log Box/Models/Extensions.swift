//
//  Extensions.swift
//  Log Box
//
//  Created by itay gervash on 16/04/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit
import AVFoundation

extension UIView {

    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
         
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
             let mask = CAShapeLayer()
             mask.path = path.cgPath
             self.layer.mask = mask
    
    }


}

extension UIViewController {
    
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

extension String {
    func separate(every stride: Int, with separator: Character) -> String {
        return String(enumerated().map { $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1]}.joined())
    }
}

extension UIResponder {
    
    func getFormattedTimeFromSeconds(seconds: Int) -> String {
        
        var times: [Int] = []
        var timesString: [String] = []
        var result = ""
        
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = (seconds % 3600) % 60
        
        if hours != 0 {
            times.append(hours)
        }

        times.append(minutes)
        times.append(secs)
        
        for time in times {
            if String(time).count == 1 {
                timesString.append("0\(time)")
            } else {
                timesString.append("\(time)")
            }
        }
        
        for time in timesString {
            result.append(time)
        }
        
        result = result.separate(every: 2, with: ":")
        return result
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
}

enum RecState {
    case inactive
    case active
    case paused
}

enum PlayState {
    case inactive
    case active
    case paused
}

enum Sort {
    case alphabeticAscending
    case alphabeticDescending
    case chronologicAscending
    case chronologicDescending
}

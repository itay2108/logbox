//
//  UIResponder+TimeFormat.swift
//  Log Box
//
//  Created by itay gervash on 24/05/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit

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
}

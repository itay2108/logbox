//
//  LogCellTableViewCell.swift
//  Log Box
//
//  Created by itay gervash on 16/04/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit
import AVFoundation

class LogCell: UITableViewCell, AVAudioPlayerDelegate {

    @IBOutlet weak var logTitle: UILabel!
    @IBOutlet weak var logDuration: UILabel!
    @IBOutlet weak var logDate: UILabel!
    
    func setData(with log: Log) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d YYYY"
        
        logTitle.text = log.name
        logDate.text =  dateFormatter.string(from: log.date)
        
        do {
            let player = try AVAudioPlayer(data: log.recording)
            let duration = getFormattedTimeFromSeconds(seconds: Int(player.duration))
            logDuration.text = duration
            
        } catch {
            print("error parsing recording info from log: \(error)")
        }
        

        
    }

}

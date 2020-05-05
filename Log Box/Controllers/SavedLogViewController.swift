//
//  SavedLogViewController.swift
//  Log Box
//
//  Created by itay gervash on 07/04/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit
import RealmSwift
import AVFoundation
import Speech

class SavedLogViewController: UIViewController, AVAudioPlayerDelegate {

    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var currentRecTime: UILabel!
    @IBOutlet weak var recDuration: UILabel!
    @IBOutlet weak var transcriptLabel: UITextView!
    @IBOutlet var tabBarButtons: [UIButton]!
    @IBOutlet weak var logTitle: UITextField!
    
    @IBOutlet weak var mainTabBar: UIView!
    @IBOutlet var playbackTabBar: UIView!
    @IBOutlet weak var pauseToggleButton: UIButton!
    
    let paths = NSSearchPathForDirectoriesInDomains( .documentDirectory, .userDomainMask, true)
    
    private var realm = try! Realm()
    private let def = UserDefaults.standard
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var fileNameMemory: String?

    public var recordingNameToDisplay: String! {
        didSet {
            print("log name to display:", String(describing: recordingNameToDisplay))
            realm(getLogWithName: recordingNameToDisplay!)
            print("log is:", String(describing: log))
        }
    }
    public var log: Log?
    
    private var audioSession: AVAudioSession!
    private var player: AVAudioPlayer!
    
    private var playState: PlayState = .inactive {
        didSet {
            switch playState {
            case .active:
               pauseToggleButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            case .paused:
               pauseToggleButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            default:
                pauseToggleButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        removeMiddleVCsFromStack()
        slider.setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
        
        clearNavBarSeparator()
        if let success = createAudioSessionObject() {
            audioSession = success
        }
        
        slider.isContinuous = false
        
        if let safeLog = log {
            print(safeLog)
            setUI(byLog: safeLog)
            
            let recordingURL = prepareRecognitionURL(from: log)
            
            recognizeFile(url: recordingURL)
        }

        logTitle.delegate = self
        self.setupHideKeyboardOnTap()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    //MARK: - IBActions

    @IBAction func playBackBtnPressed(_ sender: UIButton) {

        guard log != nil else { print("log is nil when trying to play recording"); return }
        
        displayPlaybackTabBar(show: true)
        playM4AAudio(from: log!)
        
        playState = .active
    }
    
    @IBAction func togglePauseOnTabBar(_ sender: UIButton) {
        
        guard player != nil else { print("player is nil"); return }
        
        
        if playState == .active {
            player.pause()
            playState = .paused
            
        } else {
            player.play()
            playState = .active
        }
    }
    
    @IBAction func backFromPlaybackTabBar(_ sender: UIButton) {
        
        displayPlaybackTabBar(show: false)
        stopAudio()
    }
    
    @IBAction func sliderMoved(_ sender: UISlider) {
        guard player != nil else { return }
        
        player.currentTime = Double(slider.value) * player.duration
        
        if playState != .active {
            player.play()
            playState = .active
        }
    }

    
    //MARK: - Audio methods
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("finish playing")
        if flag {
            playState = .inactive
        }
    }
    
    
    func playM4AAudio(from log: Log) {
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)

                /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
                player = try AVAudioPlayer(data: log.recording)
                
                player.delegate = self
                player.play()
                updateUIByCurrentRecTime()

            } catch let error {
                print(error.localizedDescription)
            }
            
    }
    
    func stopAudio() {
        guard player != nil else { return }
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            player.stop()
        } catch {
            print("error stopping avaudioplayer")
        }
    }
    
    //MARK: - Database Methods
    

    func realm(getLogWithName name: String) {
        //log = realm.object(ofType: Log.self, forPrimaryKey: name)
        let logs = realm.objects(Log.self)
        
        for object in logs {
            if object.name == name {
                log = object
            }
        }
    }
    
    
    func setUI(byLog data: Log) {
        
        currentRecTime.text = "00:00"
        logTitle.text = data.name
        do {
            if let recording = log?.recording {
                player = try AVAudioPlayer(data: recording)
                player.delegate = self
                recDuration.text = getFormattedTimeFromSeconds(seconds: Int(round(player.duration)))
            } else {
                print("unable to get recording data")
            }
        } catch {
            print("error attaching recording to player: \(error)")
        }
        if data.isDefaultName {
            logTitle.textColor = UIColor(named: "silver")
        }
    }
    
    
    //MARK: - UI Methods
    
    public func updateUIByCurrentRecTime() {
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
        timer.fire()
        
    }
    
    func displayPlaybackTabBar(show: Bool) {
        
        playbackTabBar.translatesAutoresizingMaskIntoConstraints = false
        let bottomConstraint = NSLayoutConstraint(item: playbackTabBar!, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: playbackTabBar!, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: playbackTabBar!, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: playbackTabBar!, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0)
        
        if show {
        self.view.addSubview(playbackTabBar)
        self.view.bringSubviewToFront(playbackTabBar)
            //print(playbackTabBar.isDescendant(of: self.view))
        NSLayoutConstraint.activate([bottomConstraint, leadingConstraint, trailingConstraint, widthConstraint])
        } else {
            self.playbackTabBar.removeFromSuperview()
        }
    }
    
    @objc func dismissKeyboard(_ sender: Any) {
        logTitle.resignFirstResponder()
    }
    
    //MARK: - Internal Methods
    
    @objc func updateTimer() {
        slider.setValue(Float((self.player.currentTime) / (self.player.duration)), animated: false)
        currentRecTime.text = getFormattedTimeFromSeconds(seconds: Int(round(player.currentTime)))
    }
    
    func recognizeFile(url: URL?) {
       guard let myRecognizer = SFSpeechRecognizer() else { print("speech recognition is not available at this locale"); return }
       guard url != nil else { print("url is nil"); return }
       print("performing recognition")
        
       if !myRecognizer.isAvailable { print("speech recognition is not available at this locale"); return }

       let request = SFSpeechURLRecognitionRequest(url: url!)
       myRecognizer.recognitionTask(with: request) { (result, error) in
        
          guard let result = result else { print("recognition failed"); return }

          
          if result.isFinal {
             // Jacob De La Bergoolah says: set result label to final result here
            self.transcriptLabel.text = result.bestTranscription.formattedString
          }
       }
    }
    
    func prepareRecognitionURL(from log: Log?) -> URL? {
        guard log != nil else { print("found nil when preparing log recording recognition task"); return nil }
        
        let recordingURL = getDocumentsDirectory().appendingPathComponent("RecognitionQueue.m4a")
        print("preparing URL...")
        do {
            try log?.recording.write(to: recordingURL)
        } catch {
            print("error writing recording data to local URL: \(error)")
            return nil
        }
        
        return recordingURL
    }


}

extension SavedLogViewController: UITextFieldDelegate {
    
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        
        logTitle.resignFirstResponder()
        
        //check if the title is not blank, then save the text as the new title in realm
        if textField.text != "" {
            do {
                try realm.write {
                    log?.isDefaultName = false
                    log?.name = logTitle.text ?? ""
                }
            } catch {
                print("error modifying log properties in realm \(error)")
            }
        } else {
            //if title is in fact blank - change the textfield text to the previous title and do not commit any modification to the realm
            textField.text = textField.placeholder
            textField.placeholder = nil
//            if let safeFileName = fileNameMemory {
//              textField.text = safeFileName
//            }
        }
        
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.placeholder = textField.text
        //fileNameMemory = textField.text
        textField.text = ""
        logTitle.textColor = UIColor(named: "dark-navy")
    }
}


//To Do:
// 1. toggle play/pause button image ------------------------------------ DONE
// 2. when playing after pause - play from stopping point --------------- DONE
// 3. if name began editing but not changed - return to previous name --- DONE
// 4. does speech recognition work?

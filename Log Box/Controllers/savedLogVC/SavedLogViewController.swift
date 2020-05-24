//
//  SavedLogViewController.swift
//  Log Box
//
//  Created by itay gervash on 07/04/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//
//To Do:
//
// 1. toggle play/pause button image ------------------------------------ DONE
// 2. when playing after pause - play from stopping point --------------- DONE
// 3. if name began editing but not changed - return to previous name --- DONE
// 4. does speech recognition work? ------------------------------------- DONE
// 5. only preform recognition if not preformed yet --------------------- DONE
// 6. animate activity indicator when recognizing speech ---------------- DONE
// 7. forward and backward playback button implementation --------------- DONE
// 8. try to animate playback tab bar ----------------------------------- DONE

import UIKit
import RealmSwift
import AVFoundation
import Speech
import Motion
import Hero

class SavedLogViewController: UILogBoxVC, AVAudioPlayerDelegate {

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

    public var recordingNameToDisplay: String! {
        didSet {
            print("log name to display:", String(describing: recordingNameToDisplay))
            realm(getLogWithName: recordingNameToDisplay!)
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
        if let object = createAudioSessionObject() {
            audioSession = object
        }
        
        slider.isContinuous = false
        transcriptLabel.text = ""
        
        if let safeLog = log {
            print(safeLog)
            setUI(byLog: safeLog)
            
            if safeLog.transcript == nil {
                let recordingURL = prepareRecognitionURL(from: log)
                recognizeFile(url: recordingURL)
            } else {
                transcriptLabel.text = safeLog.transcript
            }
            
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
        
        if playState == .inactive {
        playM4AAudio(from: log!)
        playState = .active
        } else if playState == .paused {
            
        }
        
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
    
    @IBAction func forwardPlaybackPressed(_ sender: Any) {
        guard player != nil else { print("player is nil"); return }
        
        var timePoint = player.currentTime + 30.0
        
        if timePoint > player.duration {
            timePoint = player.duration
        }

        print(timePoint)
        
        player.currentTime = timePoint
        
    }
    
    @IBAction func backwardPlaybackPressed(_ sender: Any) {
        guard player != nil else { print("player is nil"); return }
        
        var timePoint = player.currentTime - 30.0
        
        if timePoint < 0 {
            timePoint = 0
        }

        print(timePoint)
        
        player.currentTime = timePoint
        
    }
    
    
    
    @IBAction func backFromPlaybackTabBar(_ sender: UIButton) {
        print("back")
        
        displayPlaybackTabBar(show: false)

        player.pause()
        playState = .paused
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
            player.stop()
            try AVAudioSession.sharedInstance().setActive(false)
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
        playbackTabBar.alpha = 0
        playbackTabBar.animate([.fadeIn, .duration(0.2)], completion: nil)

        NSLayoutConstraint.activate([bottomConstraint, leadingConstraint, trailingConstraint, widthConstraint])
        } else {
            self.playbackTabBar.animate([.fadeOut, .duration(0.2)], completion: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
              self.playbackTabBar.removeFromSuperview()
            }
           
        }
    }
    
    @objc func dismissKeyboard(_ sender: Any) {
        logTitle.resignFirstResponder()
    }
    
    func activityIndicator(size: Int, addTo view: UIView) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
        activityIndicator.color = .red
        view.addSubview(activityIndicator)
        
        return activityIndicator
    }
    
    //MARK: - Internal Methods
    
    @objc func updateTimer() {
        slider.setValue(Float((self.player.currentTime) / (self.player.duration)), animated: false)
        currentRecTime.text = getFormattedTimeFromSeconds(seconds: Int(round(player.currentTime)))
    }
    
    func recognizeFile(url: URL?) {
       guard let myRecognizer = SFSpeechRecognizer() else { print("speech recognition is not available at this locale"); return }
       guard url != nil else { print("url is nil"); return }
       print("performing recognition...\n")
        
        let loading = activityIndicator(size: 32, addTo: self.view)
        loading.startAnimating()
        
       if !myRecognizer.isAvailable { print("speech recognition is not available at this locale"); return }

       let request = SFSpeechURLRecognitionRequest(url: url!)
       myRecognizer.recognitionTask(with: request) { (result, error) in
        
        guard let result = result else { print("recognition failed"); loading.stopAnimating(); loading.removeFromSuperview(); return }

          
          if result.isFinal {
             // Jacob De La Bergoolah says: set result label to final result here
            loading.stopAnimating()
            loading.removeFromSuperview()
            
            self.transcriptLabel.text = result.bestTranscription.formattedString
            
            do {
                try self.realm.write {
                    self.log?.transcript = result.bestTranscription.formattedString
                }
            } catch {
                print("error writing transcription to realm \(error)")
            }
            
            self.remove(file: url)
          }
       }
    }
    
    func prepareRecognitionURL(from log: Log?) -> URL? {
        guard log != nil else { print("found nil when preparing log recording recognition task"); return nil }
        
        let recordingURL = getDocumentsDirectory().appendingPathComponent("RecognitionQueue.m4a")
        print("preparing URL...\n")
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
        }
        
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.placeholder = textField.text
        //fileNameMemory = textField.text
        textField.text = ""
        logTitle.textColor = UIColor(named: "dark-navy")
    }
}

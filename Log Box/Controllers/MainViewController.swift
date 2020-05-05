//
//  MainViewController.swift
//  Log Box
//
//  Created by itay gervash on 06/04/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit
import Speech
import AVFoundation
import RealmSwift


class MainViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    @IBOutlet weak var recordingTab: UIView!
    @IBOutlet weak var recordingTabConstraint: NSLayoutConstraint!
    @IBOutlet weak var recordingTimeLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var recordingButton: UIButton!
    @IBOutlet weak var allLogsTableView: UITableView!
    @IBOutlet var recordingTabViews: [UIView]!
    @IBOutlet weak var recordingIndicator: UIImageView!
    
    private let realm = try! Realm()
    private let def = UserDefaults.standard
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private let dateFormatter = DateFormatter()
    public var logs: Results<Log>?

    
    private var audioSession: AVAudioSession!
    private var recorder: AVAudioRecorder!
    private var player: AVAudioPlayer!
    private var currentRecordingURL: URL?
    private var timer: Timer?
    
    
    public var recState = RecState.inactive {
        didSet {
            print(recState)
            recordingBarUIUpdate(by: recState)
        }
    }
    
    private var numberOfRecordings = 0
    private var isExpanded = false
    private var recordingNameToPass: String?
    private var secondsCounter = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHideKeyboardOnTap()
        renderDefaultUI()
        clearNavBarSeparator()
        requestPermissions()
        audioSession = createAudioSessionObject()
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
        dateFormatter.dateFormat = "d MMM YYYY HH:mm:ss"
        logs = getLogsFromRealm()
        tableView(sort: .chronologicDescending)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        logs = getLogsFromRealm()
        allLogsTableView.reloadData()
    }
    
    
    
    @IBAction func recButtonPressed(_ sender: Any) {
        
        if recState == .active {
            stopRecording()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.performSegue(withIdentifier: "homeToSaved", sender: self)
            }
        } else if recState == .inactive {
            
            recState = .active
            startRecording(delay: 0.2)
            updateRecordingTimeLabel(activate: true)
            
        } else if recState == .paused {
            
            recState = .active
            recorder.record()
            updateRecordingTimeLabel(activate: true)
            
        }
    }
    
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        
        guard recorder != nil else { print("recorder is nil"); return }
        guard isExpanded else { return }
        
        if recState == .active {
            //pause recording
            recorder.pause()
            recState = .paused
            updateRecordingTimeLabel(activate: false)
            
        } else if recState == .paused {
            //save recording
            stopRecording()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.performSegue(withIdentifier: "homeToSaved", sender: self)
            }
        }
    }
    
    
    @IBAction func trashButtonPressed(_ sender: UIButton) {
        guard recorder != nil else { return }
        
        let alert = defaultAlert(with: "Discard Recording", message: "Are you sure you want to discard this recording? This cannot be undone.")
        let discardAction = UIAlertAction(title: "Discard", style: .destructive) { (discard) in
            
            self.recorder.stop()
            self.recorder.deleteRecording()
            self.recState = .inactive
            self.updateRecordingTimeLabel(activate: false)
            
        }
        alert.addAction(discardAction)
        present(alert, animated: true)
        
        
    }
    
    
    
    //MARK: - Audio Methods
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            recState = .inactive
        }
    }
    
    
    func startRecording(delay: Double) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            
            self.currentRecordingURL = self.getDocumentsDirectory().appendingPathComponent("Recording.m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            do {
                guard let recURL = self.currentRecordingURL else { return }
                self.recorder = try AVAudioRecorder(url: recURL, settings: settings)
                self.recorder.delegate = self
                self.recorder.isMeteringEnabled = true
                self.recorder.record()
                print("recording...")
                
            } catch {
                self.stopRecording()
                print("there was an error with the recording: \(error as NSError)")
            }
        }
        
    }
    
    func stopRecording() {
        
        guard recorder != nil else { return }
        
        recorder.stop()
        recorder = nil
        recState = .inactive
        updateRecordingTimeLabel(activate: false)
        print("recording stopped")
        
        let recording = Log()
        
        if let recURL = currentRecordingURL {
            do {
                try recording.recording = Data(contentsOf: recURL)
            } catch {
                print("error attaching recording Data to Realm object: \(error)")
            }
            setLogParameters(log: recording)
            print(String(describing: recording))
            realm(write: recording)
            
        }
        
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording()
            print("error interrupted")
        }
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    //MARK: - Permissions
    
    func requestPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { (success) in
            if success {
                print("success")
                //proceed to request speech recognition auth
                self.requestSpeechRecognitionAuth()
            } else {
                print("failure")
                //show user a message showing he needs to allow voice recognition
            }
        }
    }
    
    
    
    func requestSpeechRecognitionAuth() {
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            DispatchQueue.main.async {
                if status == .authorized {
                    print("success")
                    self.def.set(true, forKey: "allowSpeech")
                    //self.performSegue(withIdentifier: "homeToRecording", sender: self)
                } else {
                    print("fail")
                    self.def.set(false, forKey: "allowSpeech")
                }
            }
        }
        
    }
    
    //MARK: - Database methods
    
    
    func getLogsFromRealm() -> Results<Log> {
        
        let result = realm.objects(Log.self)
        return result
        
    }
    
    func realm(write: Object) {
        do {
            try realm.write {
                realm.add(write.self)
            }
        } catch {
            print("error adding object to realm")
        }
        
    }
    
    func getDefaultNewRecordingName() -> String? {
        
        let input = Date()
        
        let date = dateFormatter.string(from: input)
        
        let name = "New Log at \(date)"
        return name
    }
    
    func setLogParameters(log: Log) {
        log.date = Date()
        if let name = getDefaultNewRecordingName() {
            log.name = name
            self.recordingNameToPass = name
        }
    }
    
    //MARK: - UI Manipulation
    
    func createSoundVisualizer(samples: Int) {

        let soundVisualizer = AudioVisualizationView(frame: CGRect(x: 0.0, y: 0.0, width: 350, height: 64))
        soundVisualizer.meteringLevelBarWidth = 5
        soundVisualizer.meteringLevelBarInterItem = 1
        soundVisualizer.meteringLevelBarCornerRadius = 5
        soundVisualizer.backgroundColor = UIColor(named: "silver")
        soundVisualizer.audioVisualizationMode = .write

    }
    
    
    func recordingBarUIUpdate(by state: RecState) {
        switch state {
        case .active:
            expandRecordingBar()
            
            recordingIndicator.tintColor = UIColor(named: "brand-red")
            recordingButton.setBackgroundImage(UIImage(named: "rec-active"), for: .normal)
            pauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            
        case .inactive:
            collapseRecordingTab()
            
            recordingButton.setBackgroundImage(UIImage(named: "rec"), for: .normal)
            pauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            
        case .paused:
            pauseButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            
            recordingIndicator.tintColor = UIColor(named: "silver")
            recordingButton.setBackgroundImage(UIImage(named: "rec"), for: .normal)
        }
    }
    
    func expandRecordingBar() {
        guard isExpanded == false else { return }
        
        expand(for: recordingTabConstraint, by: 2, duration: 0.2)
        areHidden(views: recordingTabViews, hidden: false, animated: true)
        isExpanded = true
    }
    
    func collapseRecordingTab() {
        guard isExpanded == true else { return }
        
        expand(for: recordingTabConstraint, by: 0.5, duration: 0.2)
        areHidden(views: recordingTabViews, hidden: true, animated: true)
        isExpanded = false
    }
    
    
    func areHidden(views: [UIView], hidden: Bool, animated: Bool) {
        for view in views {
            
            if animated {
                for view in views {
                    if hidden {
                        view.alpha = 1.0
                        UIView.animate(withDuration: 0.3) {
                            view.alpha = 0.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            view.isHidden = hidden
                        }
                    } else {
                        view.alpha = 0.0
                        UIView.animate(withDuration: 0.3) {
                            view.alpha = 1.0
                        }
                        view.isHidden = hidden
                    }
                }
            } else {
                view.isHidden = hidden
            }
        }
    }
    
    
    func expand(for constraint: NSLayoutConstraint, by multiplier: Float, duration: TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseInOut, animations: {
            constraint.constant *= CGFloat(multiplier)
            self.view.layoutIfNeeded()
        })
    }
    
    func expand(for constraint: NSLayoutConstraint, to height: Float, duration: TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseInOut, animations: {
            constraint.constant = CGFloat(height)
            self.view.layoutIfNeeded()
        })
    }
    
    func renderDefaultUI() {
        recordingTab.clipsToBounds = false
        recordingTab.layer.cornerRadius = 10
        recordingTab.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        areHidden(views: recordingTabViews, hidden: true, animated: true)
        
        allLogsTableView.layer.cornerRadius = allLogsTableView.frame.height / 20
        allLogsTableView.rowHeight = 72
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "homeToSaved" {
            let destination = segue.destination as! SavedLogViewController
            if let name = recordingNameToPass {
                destination.recordingNameToDisplay = name
            }
            
        }
    }
    
    //MARK: - Internal methods
    
    func updateRecordingTimeLabel(activate: Bool) {
        
        if activate {
            guard timer == nil else { return }
            
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
            timer!.fire()
        } else {
            guard timer != nil else { return }
            
            timer!.invalidate()
            timer = nil
            if recState != .paused {
                secondsCounter = 0
            }
        }
    }
    
    @objc func updateTimer() {
        secondsCounter += 1
        recordingTimeLabel.text = getFormattedTimeFromSeconds(seconds: secondsCounter)
    }
    
    func tableView(sort by: Sort) {
        
        guard logs != nil else { print("logs are still nil"); return }
        
        switch by {
        case .alphabeticAscending:
            logs = logs?.sorted(byKeyPath: "name", ascending: true)
        case .alphabeticDescending:
            logs = logs?.sorted(byKeyPath: "name", ascending: false)
        case .chronologicAscending:
            logs = logs?.sorted(byKeyPath: "date", ascending: true)
        case .chronologicDescending:
            logs = logs?.sorted(byKeyPath: "date", ascending: false)
        }
        
    }
    
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = logs?.count {
            print("count is \(count)")
            return count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        logs = logs?.sorted(byKeyPath: "date", ascending: false)
        
        let cell = allLogsTableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath) as! LogCell
        if let result = logs?[indexPath.row] {
            cell.setData(with: result)
        }
        cell.layer.cornerRadius = allLogsTableView.layer.cornerRadius
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        recordingNameToPass = logs?[indexPath.row].name
        performSegue(withIdentifier: "homeToSaved", sender: self)
    }
    
    
}



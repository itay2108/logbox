//
//  LogViewController.swift
//  Log Box
//
//  Created by itay gervash on 06/04/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit
import Speech
import AVFoundation
import RealmSwift

class RecordingViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    
    private let realm = try! Realm()
    private let def = UserDefaults.standard
    private var isRecordingActive = false
    
    private var existingTranscription: String?
    private var isResuming = false

    private let recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.startRecording()
        }

    }
    
    //MARK: - Recording manipulation functions
    
    func startRecording() {
        print("is resuming? -\(isResuming)")
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
        self.isRecordingActive = true
            
            var isFinal = false
            
            if result != nil {
                
                if self.isResuming {
                    if let prevTrans = self.existingTranscription, let newTrans = result?.bestTranscription.formattedString {
                        self.textView.text = prevTrans + "\n\n" + newTrans
                    }
                } else {
                self.textView.text = result?.bestTranscription.formattedString
                }
                
                
                isFinal = (result?.isFinal)!
            }
            
            if error != nil {
                self.stopRecording()
                print("stopping recording de to an error")
                
                self.recognitionRequest = nil
                self.recognitionTask = nil

            }
            
            if isFinal {
                self.triggerPause()
                Vibration.medium.vibrate()
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }

        
        do {
        try audioSession.setPreferredIOBufferDuration(0.9)
        } catch {
            print("error")
        }
        
        self.recordButton.setBackgroundImage(UIImage(named: "rec-active"), for: .normal)

        print(audioSession.inputGain, audioSession.sampleRate, audioSession.ioBufferDuration, audioSession.preferredIOBufferDuration)
        
    }
    
    func stopRecording() {
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        self.recordButton.setBackgroundImage(UIImage(named: "rec"), for: .normal)
        
        isRecordingActive = false
        existingTranscription = textView.text
    }
    
    func triggerPause() {
        if isRecordingActive {
            recordButton.setBackgroundImage(UIImage(named: "rec"), for: .normal)
            pauseButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            
            
            stopRecording()
            isResuming = true
        } else {
            recordButton.setBackgroundImage(UIImage(named: "rec-active"), for: .normal)
            pauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            isRecordingActive = true
            
            startRecording()
            
        }
    }
    
    @IBAction func recBtnPressed(_ sender: UIButton) {
        
        if isRecordingActive {
            print("stopping rec")
            DispatchQueue.main.async {
                self.stopRecording()
            }
            performSegue(withIdentifier: "recordingToSaved", sender: self)
        } else {
            
            recordButton.setBackgroundImage(UIImage(named: "rec-active"), for: .normal)
            pauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            startRecording()
        }
        
    }
    
    
    @IBAction func pauseBtnPressed(_ sender: UIButton) {
        
        if isRecordingActive {
            triggerPause()
        } else {
            
            stopRecording()
            performSegue(withIdentifier: "recordingToSaved", sender: self)
        }

    }
    
    //MARK: - Database methods
    
    func realm(create objectWithName: String, transcipt text: String, recording: Data) -> Object {
        
        let log = Log()
        log.name = objectWithName
        log.transcript = text
        log.date = Date()
        log.recording = recording
        
        return log
    }
    
    
    func realm<T: Object>(get object: T) -> Results<T> {
        
        let result = realm.objects(T.self)
        return result

    }
    
    func realm(write object: Object) {
       
        do {
            try realm.write {
                realm.add(object)
            }
        } catch {
            print(error)
        }
        
    }
    
    
    
}

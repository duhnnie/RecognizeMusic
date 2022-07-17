//
//  ViewController.swift
//  RecognizeMusic
//
//  Created by Daniel on 4/6/22.
//

import UIKit
import ShazamKit

class ViewController: UIViewController, SHSessionDelegate, AVAudioRecorderDelegate {

//    @IBOutlet weak var songInfoTxt: UILabel!
    var recordButton: UIButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!

    // The session for the active ShazamKit match request.
    var session: SHSession?

    override func viewDidLoad() {
        super.viewDidLoad()
//        songInfoTxt.text = "recognizing..."

        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)

            recordingSession.requestRecordPermission { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        listRecordings()
//                        self.loadRecordingUI()
//                        startRecording()
//                        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { Timer in
//                            finishRecording(success: true)
//                        }
                    } else {
                        print("There's no permission for recording.")
                    }
                }
            }
        } catch {
            print("Error at trying to init recording \(error.localizedDescription)")
        }
    }

    func listRecordings() {
        do {
            let recordingsDirectory = getDocumentsDirectory()
            let recordings = try FileManager.default.contentsOfDirectory(atPath: recordingsDirectory.path)

            print(recordings)
        } catch {
            print("An error ocurred at trying to list recordings \(error.localizedDescription)")
        }
    }

    func loadRecordingUI() {
        recordButton = UIButton(frame: CGRect(x: 64, y: 64, width: 128, height: 64))
        recordButton.setTitle("Tap to record", for: .normal)
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        view.addSubview(recordButton)
    }

    @objc func recordTapped() {
        print("carajo")
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        return paths[0]
    }

    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil

        // Additional threatment depending on success or not
    }

    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("record.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()

//            recordButton.setTitle("")
        } catch {
            finishRecording(success: false)
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}

extension AVAudioSession {
    func hasPermissionToRecord() async -> Bool {
        await withCheckedContinuation { continuation in
            requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
}


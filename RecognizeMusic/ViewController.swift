//
//  ViewController.swift
//  RecognizeMusic
//
//  Created by Daniel on 4/6/22.
//

import UIKit
import ShazamKit

class ViewController: UIViewController, SHSessionDelegate {

    @IBOutlet weak var songInfoTxt: UILabel!
    let audioEngine = AVAudioEngine()
    let mixerNode = AVAudioMixerNode()

    // The session for the active ShazamKit match request.
    var session: SHSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        songInfoTxt.text = "recognizing..."

        Task(priority: .background) {
            do {
                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                    throw NSError()
                }
            } catch {
//                speakError(error)
                throw NSError()
            }
        }

        recognizeSong()
    }

    private func recognizeSong() {
        do {
            configureAudioEngine()
            try startListening()
        } catch {
            print(error)
        }
        // Session
//        let session = SHSession()
//        // Delegate
//        session.delegate = self
//
//        do {
//            let audioEngine = AVAudioEngine()
//            let mixerNode = AVAudioMixerNode()
//        } catch {
//            print(error)
//        }
    }

    func addAudio(buffer: AVAudioPCMBuffer, audioTime: AVAudioTime) {
        // Add the audio to the current match request.
        session?.matchStreamingBuffer(buffer, at: audioTime)
    }

    func stopListening() {
        // Check if the audio engine is already recording.
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }

    func startListening() throws {
        // Throw an error if the audio engine is already running.
        guard !audioEngine.isRunning else { return }
        let audioSession = AVAudioSession.sharedInstance()

        // Ask the user for permission to use the mic if required then start the engine.
        try audioSession.setCategory(.playAndRecord)
        audioSession.requestRecordPermission { [weak self] success in
            guard success, let self = self else { return }
            try? self.audioEngine.start()
        }
    }

    func configureAudioEngine() {
        // Get the native audio format of the engine's input bus.
        let inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)

        // Set an output format compatible with ShazamKit.
        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)

        // Create a mixer node to convert the input.
        audioEngine.attach(mixerNode)

        // Attach the mixer to the microphone input and the output of the audio engine.
        audioEngine.connect(audioEngine.inputNode, to: mixerNode, format: inputFormat)
        audioEngine.connect(mixerNode, to: audioEngine.outputNode, format: outputFormat)

        // Install a tap on the mixer node to capture the microphone audio.
        mixerNode.installTap(onBus: 0,
                             bufferSize: 8192,
                             format: outputFormat) { buffer, audioTime in
            // Add captured audio to the buffer used for making a match.
            self.addAudio(buffer: buffer, audioTime: audioTime)
        }
    }

    func session(_ session: SHSession, didFind match: SHMatch) {
        let matchedMediaItems = match.mediaItems

        matchedMediaItems.forEach { matchedMedia in
            print(matchedMedia.artist ?? "no artist")
            print(matchedMedia.title)
            print(matchedMedia.artworkURL)
            print(matchedMedia.songs)

            DispatchQueue.main.async {
                self.songInfoTxt.text = "\(matchedMedia.artist!) - \"\(matchedMedia.title!)\""
            }
        }
    }

    func match(_ catalog: SHCustomCatalog) throws {
        // Create a session if one doesn't already exist.
        if (session == nil) {
            session = SHSession(catalog: catalog)
            session?.delegate = self
        }

        // Start listening to the audio to find a match.
        try startListening()
    }

    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        if let error = error {
            print(error)
            songInfoTxt.text = error.localizedDescription
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


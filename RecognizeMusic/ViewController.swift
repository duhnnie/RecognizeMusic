//
//  ViewController.swift
//  RecognizeMusic
//
//  Created by Daniel on 4/6/22.
//

import UIKit
import ShazamKit

class ViewController: UIViewController, SHSessionDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        recognizeSong()
    }

    private func recognizeSong() {
        // Session
        let session = SHSession()
        // Delegate
        session.delegate = self

        do {
            // Get track
            guard let url = Bundle.main.url(forResource: "song", withExtension: "m4a") else {
                print("Failed to get song url")
                return
            }

            guard let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else {
                print("Error at creating audio format")
                return
            }

            let generator = SHSignatureGenerator()

            // create audio file
            let audioFile = try AVAudioFile(forReading: url)

            guard
                let inputBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: 44100 * 10),
                let outputBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: 44100 * 10)
            else {
                print("error at creating input/output buffer")
                return
            }

            let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                do {
                    try audioFile.read(into: inputBuffer)
                    outStatus.pointee = .haveData
                    return inputBuffer
                } catch {
                    if audioFile.framePosition >= audioFile.length {
                        outStatus.pointee = .endOfStream
                        return nil
                    } else {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                }
            }

            guard let converter = AVAudioConverter(from: audioFile.processingFormat, to: audioFormat) else {
                print("error at converting audio")
                return
            }

            let status = converter.convert(to: outputBuffer, error: nil, withInputFrom: inputBlock)

            try generator.append(outputBuffer, at: nil)

            if status == .inputRanDry {
                return
            }
            // Audio -> Buffer
//            guard let buffer = AVAudioPCMBuffer(
//                pcmFormat: audioFile.processingFormat,
//                frameCapacity: AVAudioFrameCount(audioFile.length / 2)
//            ) else {
//                print("Failed to create the buffer")
//                return
//            }
//
//            try audioFile.read(into: buffer)
//            // Signature generator
//            let generator = SHSignatureGenerator()
//            try generator.append(buffer, at: nil)
            // Create signature
            let signature = generator.signature()

            session.match(signature)
        } catch {
            print(error)
        }
    }

    func session(_ session: SHSession, didFind match: SHMatch) {
        let matchedMediaItems = match.mediaItems

        matchedMediaItems.forEach { matchedMedia in
            print(matchedMedia.artist ?? "no artist")
            print(matchedMedia.title)
            print(matchedMedia.artworkURL)
        }
    }

    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        if let error = error {
            print(error)
        }
    }
}


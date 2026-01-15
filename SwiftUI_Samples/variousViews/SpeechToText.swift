//
//  SpeechToText.swift
//  exp
//
//  Created by Peter Rogers on 15/01/2026.
//

import SwiftUI
import Speech
import AVFoundation
import Combine

final class SpeechToText: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var status: String = "Ready"

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { auth in
            DispatchQueue.main.async {
                self.status = auth == .authorized ? "Speech permission OK" : "Speech permission denied"
            }
        }

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.status = "Mic permission denied"
                }
            }
        }
    }

    func start() {
        guard !isRecording else { return }
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            status = "Speech recognizer unavailable"
            return
        }

        isRecording = true
        status = "Listening…"

        configureAudioSession()
        startRecognition()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            status = "Audio session error"
        }
    }

    private func startRecognition() {
        // Clean up previous task
        task?.cancel()
        task = nil

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        self.request = req

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        if !audioEngine.isRunning {
            audioEngine.prepare()
            try? audioEngine.start()
        }

        task = speechRecognizer?.recognitionTask(with: req) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }

                // iOS ends tasks periodically — restart automatically
                if error != nil || result?.isFinal == true {
                    self.restartRecognition()
                }
            }
        }
    }

    private func restartRecognition() {
        guard isRecording else { return }
        request?.endAudio()
        startRecognition()
    }

    func stop() {
        isRecording = false
        status = "Stopped"

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        request?.endAudio()
        task?.cancel()

        request = nil
        task = nil
    }
}

struct VoiceToTextView: View {
    @StateObject private var speech = SpeechToText()

    var body: some View {
        VStack {
            
            TextEditor(text: $speech.transcript)
                .frame(minHeight: 200)
                .padding(8)
                .disabled(true) // set false if you want to edit manually too

        }
        .padding()
        .onAppear {
            speech.requestPermissions()
            speech.start()
        }
        .onDisappear {
            speech.stop()
        }
    }
}

//
//  ContentView.swift
//  SwiftUI-SpeechSample
//
//  Created by NanbanTaro on 2025/04/30.
//  
//

import SwiftUI

struct ContentView: View {
    @State var liveTranscriber = LiveTranscriber()

    var body: some View {
        VStack {
            Text(liveTranscriber.text)
                .lineLimit(100)
            HStack {
                Button("start") {
                    do {
                        try liveTranscriber.start()
                    } catch {
                        print("\(error.localizedDescription)")
                    }
                }
                Button("finish") {
                    liveTranscriber.stop()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

import Speech

@Observable
final class LiveTranscriber {
    var text = ""
    private var currentSegment = ""

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "ja-JP"))!
    private var recognitionTask: SFSpeechRecognitionTask?

    private var request: SFSpeechAudioBufferRecognitionRequest?

    func start() throws {
        SFSpeechRecognizer.requestAuthorization { value in
            switch value {
            case .notDetermined:
                print("😃 notDetermined")
            case .denied:
                print("😃 denied")
            case .restricted:
                print("😃 restricted")
            case .authorized:
                print("😃 authorized")
            default:
                print("😃 default")
            }
        }

        // リクエスト
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = speechRecognizer.supportsOnDeviceRecognition
        request.addsPunctuation = true

        // マイク
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()

        // 認識タスク
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self, let result else { return }
            DispatchQueue.main.async {
                self.text = result.bestTranscription.formattedString
            }
            if /*result.isFinal || */error != nil { self.restart()}
        }
    }

    private func restart() {
        recognitionTask?.cancel()
        audioEngine.inputNode.removeTap(onBus: 0)
        try? start()
    }

    func stop() {
        recognitionTask?.finish()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}

//
//  LiveTranscriber.swift
//  SpeechSampleApp
//
//  Created by NanbanTaro on 2025/04/30.
//  
//

import Speech

@Observable
final class LiveTranscriber {
    /// 画面描画テキスト
    var text = ""
    /// 権限エラー
    var permissionError: PermissionError?
    /// 権限エラーアラート表示
    var isShowAlert = false
    /// レコーディング中
    var isRecording = false
    
    /// 現在生成されているテキスト
    private var currentSegment = ""
    /// 生成確定テキスト
    private var completeText = ""

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "ja-JP"))!
    private var recognitionTask: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    /// 最終生成時間
    private var lastSpokenAt: TimeInterval = 0
    /// 沈黙時間閾値
    private var silenceThreshold: TimeInterval = 1.2

    // MARK: - Methods

    /// 処理開始
    func start() throws {
        // 権限確認
        guard permissionError == nil else {
            isShowAlert = true
            return
        }

        // マイク
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { [weak self] buffer, _ in
            // 動作中のリクエストにバッファを流す
            self?.request?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true

        startNewTask()
    }

    /// 処理停止
    func stop() {
        recognitionTask?.finish()
        request?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        isRecording = false
    }

    /// 権限確認
    func checkPermission() {
        // マイク
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            guard let self else { return }
            if !granted {
                self.permissionError = .microphoneDenied
                self.isShowAlert = true
                return
            }
            // 音声認識
            SFSpeechRecognizer.requestAuthorization { [weak self] value in
                guard let self else { return }
                switch value {
                case .authorized:
                    break
                default:
                    self.permissionError = .speechDenied
                    self.isShowAlert = true
                }
            }
        }
    }

    // MARK: - Private

    /// 新しいタスクを開始する
    private func startNewTask() {
        let newRequest = SFSpeechAudioBufferRecognitionRequest()
        // 発話ごとに結果を返す(リアルタイムで表示させる)
        newRequest.shouldReportPartialResults = true
        // オンデバイスでの音声認識が可能であれば、オンデバイスで行う
        newRequest.requiresOnDeviceRecognition = speechRecognizer.supportsOnDeviceRecognition
        // 句読点認識ON
        newRequest.addsPunctuation = true

        request = newRequest

        // 認識タスク
        recognitionTask = speechRecognizer.recognitionTask(
            with: newRequest
        ) { [weak self] result, error in
            guard let self, let result else { return }

            // 現在の音声認識文字列を更新
            let partial = result.bestTranscription.formattedString
            self.currentSegment = partial

            // 最終音声日時を更新
            if let last = result.bestTranscription.segments.last {
                self.lastSpokenAt = last.timestamp + last.duration
            }

            // 画面描画を更新
            DispatchQueue.main.async {
                self.text = self.completeText + self.currentSegment
            }

            // Task終了判定で、リスタートし、確定文字列を格納する
            if result.isFinal || error != nil {
                self.restart()
                return
            }

            // 閾値を超えた沈黙があれば、一旦リクエストを停止させる
            // その後、上記if節が呼び出され、restartされる
            if self.lastSpokenAt > self.silenceThreshold {
                self.request?.endAudio()
            }
        }
    }

    /// 再スタート
    private func restart() {
        // 句読点、？、！がなければ、句点を打つ
        let punctuations: [Character] = ["、", "。", "？", "！"]
        if !punctuations.contains(text.last!) {
            text += "。"
        }
        completeText = text
        currentSegment = ""
        startNewTask()
    }
}

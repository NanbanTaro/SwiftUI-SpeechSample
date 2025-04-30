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
            // 文字起こしテキスト
            Text(liveTranscriber.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // 音声認識開始/停止ボタン
            Button {
                if liveTranscriber.isRecording {
                    liveTranscriber.stop()
                } else {
                    do {
                        try liveTranscriber.start()
                    } catch {
                        print("\(error.localizedDescription)")
                    }
                }
            } label: {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .overlay {
                        if liveTranscriber.isRecording {
                            Rectangle()
                                .frame(width: 32, height: 32)
                                .foregroundStyle(.red)
                        } else {
                            Circle()
                                .frame(width: 40, height: 40)
                                .foregroundStyle(.red)
                        }
                    }

            }
        }
        .onAppear() {
            liveTranscriber.checkPermission()
        }
        .alert(
            "権限エラー",
            isPresented: $liveTranscriber.isShowAlert,
            presenting: liveTranscriber.permissionError
        ) { hoge in
            Button("設定画面へ") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Task { await UIApplication.shared.open(url) }
                }
            }
        } message: { error in
            switch error {
            case .microphoneDenied: Text("マイク利用が許可されていません")
            case .speechDenied: Text("音声認識が許可されていません")
            }
        }
    }
}

#Preview {
    ContentView()
}

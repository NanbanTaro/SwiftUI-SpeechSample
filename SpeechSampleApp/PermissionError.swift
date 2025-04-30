//
//  PermissionError.swift
//  SpeechSampleApp
//
//  Created by NanbanTaro on 2025/04/30.
//  
//

/// 権限エラー
enum PermissionError: Error {
    case microphoneDenied
    case speechDenied
}

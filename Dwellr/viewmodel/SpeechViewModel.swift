import Foundation
import AVFoundation
import Speech
import SwiftUI

class SpeechRecognizer: ObservableObject {
    enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        
        var message: String {
            switch self {
            case .nilRecognizer: return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
            case .notPermittedToRecord: return "Not permitted to record audio"
            case .recognizerIsUnavailable: return "Recognizer is unavailable"
            }
        }
    }
    
    
    
    @Published var transcript: String = ""
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    init() {
        recognizer = SFSpeechRecognizer()
        do {
            Task {
                guard let recognizer = recognizer else {
                    throw RecognizerError.nilRecognizer
                }
                
                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                    throw RecognizerError.notAuthorizedToRecognize
                }
                
                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                    throw RecognizerError.notPermittedToRecord
                }
            }
        } catch {
            transcribe(error)
        }
    }
    
    @MainActor func startTranscribing() {
        print("Start transcribing...")
        do {
            try transcribe()
        } catch {
            transcribe(error)
        }
    }
    
    @MainActor func stopTranscribing() {
        print("End transcribing...")
        reset()
    }
    
    private func transcribe() throws {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw RecognizerError.recognizerIsUnavailable
        }
        
        let (audioEngine, request) = try Self.prepareEngine()
        self.audioEngine = audioEngine
        self.request = request
        
        self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let weakSelf = self else { return }
            do {
                
                try weakSelf.recognitionHandler(audioEngine: audioEngine, result: result, error: error)
            } catch {
                weakSelf.transcribe(error)
            }
        }
    }
    
    private func recognitionHandler(audioEngine: AVAudioEngine, result: SFSpeechRecognitionResult?, error: Error?) throws {
        let receivedFinalResult = result?.isFinal ?? false
        let receivedError = error != nil
        if receivedFinalResult || receivedError {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        if let result {
            try transcribe(result.bestTranscription.formattedString)
        }
    }
    
    private func transcribe(_ message: String) throws {
        print("Transcribe: \(message)")
        DispatchQueue.main.async {
            self.transcript = message
        }
    }
    
    private func transcribe(_ error: Error) {
        DispatchQueue.main.async {
            var errorMessage = ""
            if let error = error as? RecognizerError {
                errorMessage += error.message
            } else {
                errorMessage += error.localizedDescription
            }
            self.transcript = "<< \(errorMessage) >>"
        }
    }
    
    private func reset() {
        task?.cancel()
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        task = nil
    }
    
    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
}

extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
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

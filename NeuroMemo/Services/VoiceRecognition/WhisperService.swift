import Foundation
import NaturalLanguage
import Speech
import AVFoundation

class WhisperService {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Para usar con grabación en vivo
    func startLiveTranscription(resultHandler: @escaping (String?, Error?) -> Void) {
        // Verificar autorización
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                resultHandler(nil, NSError(domain: "WhisperService", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No hay autorización para reconocimiento de voz"]))
                return
            }
            
            // Configurar la sesión de audio
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Preparar la petición de reconocimiento
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = self.recognitionRequest else {
                resultHandler(nil, NSError(domain: "WhisperService", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "No se pudo crear la petición de reconocimiento"]))
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            // Configurar el micrófono
            let inputNode = self.audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            // Iniciar el motor de audio
            self.audioEngine.prepare()
            try? self.audioEngine.start()
            
            // Iniciar el reconocimiento
            self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    resultHandler(result.bestTranscription.formattedString, nil)
                }
                
                if error != nil {
                    self.stopLiveTranscription()
                    resultHandler(nil, error)
                }
            }
        }
    }
    
    func stopLiveTranscription() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    // Para usar con un archivo de audio
    func transcribe(audioData: Data, completion: @escaping (String?, Error?) -> Void) {
        // Convertir Data a un archivo temporal
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
        
        do {
            try audioData.write(to: tempFile)
            
            // Crear URL de audio y solicitud
            let audioURL = tempFile
            let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            
            // Realizar reconocimiento
            recognizer?.recognitionTask(with: request) { result, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                if let result = result {
                    completion(result.bestTranscription.formattedString, nil)
                }
            }
        } catch {
            completion(nil, error)
        }
    }
}

// SpeechProcessor.swift
import Foundation
import AVFoundation
import Speech

enum SpeechProcessorError: Error {
    case recognitionNotAvailable
    case recordingError
    case processingError(String)
    case permissionDenied
    case noAudioData
}

class SpeechProcessor {
    private let whisperService: WhisperService
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Estado
    private var isRecording = false
    private var isProcessing = false
    
    // Configuración
    private let useWhisper: Bool
    private let language: String
    
    init(language: String = "es-ES", useWhisper: Bool = true) {
        self.language = language
        self.useWhisper = useWhisper
        self.whisperService = WhisperService()
        
        // Configurar reconocedor de voz de Apple
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language))
    }
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        // Verificar si ya está grabando
        guard !isRecording else {
            completion(.failure(SpeechProcessorError.recordingError))
            return
        }
        
        // Verificar disponibilidad y permisos
        if useWhisper {
            // Usar servicio Whisper
            whisperService.startRecording { result in
                completion(result)
            }
        } else {
            // Usar reconocimiento de voz nativo
            startSpeechRecognition(completion: completion)
        }
    }
    
    func stopRecording() {
        if useWhisper {
            whisperService.stopRecording()
        } else {
            stopSpeechRecognition()
        }
        
        isRecording = false
    }
    
    // MARK: - Reconocimiento de voz nativo de Apple
    
    private func startSpeechRecognition(completion: @escaping (Result<String, Error>) -> Void) {
        // Verificar disponibilidad
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion(.failure(SpeechProcessorError.recognitionNotAvailable))
            return
        }
        
        // Verificar autorización
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                self.setupAudioSession()
                self.setupRecognition(completion: completion)
            case .denied, .restricted:
                completion(.failure(SpeechProcessorError.permissionDenied))
            case .notDetermined:
                completion(.failure(SpeechProcessorError.permissionDenied))
            @unknown default:
                completion(.failure(SpeechProcessorError.permissionDenied))
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error configurando sesión de audio: \(error)")
        }
    }
    
    private func setupRecognition(completion: @escaping (Result<String, Error>) -> Void) {
        // Crear y configurar la petición de reconocimiento
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            completion(.failure(SpeechProcessorError.processingError("No se pudo crear la petición de reconocimiento")))
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configurar entrada de audio
        let inputNode = audioEngine.inputNode
        
        // Iniciar reconocimiento
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Procesar resultado parcial
                let recognizedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
                
                if isFinal {
                    completion(.success(recognizedText))
                }
            }
            
            if error != nil || isFinal {
                // Detener audio engine
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                if !isFinal {
                    completion(.failure(error ?? SpeechProcessorError.processingError("Error desconocido")))
                }
            }
        }
        
        // Configurar buffer de audio
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Iniciar motor de audio
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            completion(.failure(error))
        }
    }
    
    private func stopSpeechRecognition() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        if let inputNode = audioEngine.inputNode as AVAudioNode? {
            inputNode.removeTap(onBus: 0)
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
    
    // MARK: - Procesamiento de texto reconocido
    
    func processRecognizedText(_ text: String, forMedicalContext: Bool = true) -> String {
        var processedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if forMedicalContext {
            // Convertir a términos médicos correctos
            processedText = correctMedicalTerms(processedText)
        }
        
        return processedText
    }
    
    private func correctMedicalTerms(_ text: String) -> String {
        // Ejemplo de correcciones específicas para términos médicos
        // En una implementación real, esto usaría un diccionario más completo
        var correctedText = text
        
        let corrections = [
            "hipocampo": "hipocampo",
            "ipocampo": "hipocampo",
            "talámo": "tálamo",
            "talamo": "tálamo",
            "hipotalamo": "hipotálamo",
            "hypotalamo": "hipotálamo",
            "bulbo raquidio": "bulbo raquídeo",
            "cerebelo": "cerebelo",
            "serebelo": "cerebelo",
            "cortex": "córtex",
            "corteza": "córtex"
        ]
        
        for (incorrect, correct) in corrections {
            // Usar expresión regular para encontrar palabras completas
            let pattern = "\\b\(incorrect)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                correctedText = regex.stringByReplacingMatches(
                    in: correctedText,
                    options: [],
                    range: NSRange(location: 0, length: correctedText.utf16.count),
                    withTemplate: correct
                )
            }
        }
        
        return correctedText
    }
}

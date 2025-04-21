import Foundation
import Speech

enum SpeechProcessingError: Error {
    case recognitionNotAvailable
    case permissionDenied
    case processingFailed
    case commandNotRecognized
    case audioSessionError
}

class SpeechProcessor: NSObject, SFSpeechRecognizerDelegate {
    static let shared = SpeechProcessor()
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var commandCallback: ((Result<VoiceCommand, Error>) -> Void)?
    
    // Comandos de voz reconocibles
    struct VoiceCommand {
        let type: CommandType
        let parameters: [String: Any]
        
        enum CommandType: String {
            case search = "buscar"
            case navigate = "ir a"
            case select = "seleccionar"
            case showInfo = "información"
            case zoomIn = "ampliar"
            case zoomOut = "reducir"
            case startQuiz = "comenzar cuestionario"
            case unknown = "desconocido"
        }
    }
    
    private override init() {
        // Inicializar con el reconocedor del idioma español
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
        super.init()
        self.speechRecognizer?.delegate = self
    }
    
    // MARK: - Control de Reconocimiento
    
    func startListening(completion: @escaping (Result<VoiceCommand, Error>) -> Void) {
        // Verificar disponibilidad
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion(.failure(SpeechProcessingError.recognitionNotAvailable))
            return
        }
        
        // Solicitar permisos
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.startRecognition(completion: completion)
                case .denied:
                    completion(.failure(SpeechProcessingError.permissionDenied))
                case .restricted, .notDetermined:
                    completion(.failure(SpeechProcessingError.permissionDenied))
                @unknown default:
                    completion(.failure(SpeechProcessingError.permissionDenied))
                }
            }
        }
    }
    
    private func startRecognition(completion: @escaping (Result<VoiceCommand, Error>) -> Void) {
        // Cancelar cualquier reconocimiento previo
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        self.commandCallback = completion
        
        // Configurar sesión de audio
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            completion(.failure(SpeechProcessingError.audioSessionError))
            return
        }
        
        // Crear y configurar el reconocimiento
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            completion(.failure(SpeechProcessingError.processingFailed))
            return
        }
        
        // Configurar para reconocimiento continuo (en tiempo real)
        recognitionRequest.shouldReportPartialResults = true
        
        // Configurar el micrófono
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Instalar el tap para capturar audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, _) in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Iniciar el motor de audio
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            completion(.failure(SpeechProcessingError.audioSessionError))
            return
        }
        
        // Iniciar el reconocimiento
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.stopListening()
                self.commandCallback?(.failure(error))
                return
            }
            
            if let result = result {
                // Procesar el texto reconocido para extraer comandos
                let recognizedText = result.bestTranscription.formattedString
                
                // Si el resultado es final o si detectamos un comando, procesarlo
                if result.isFinal || self.containsCommand(recognizedText) {
                    self.processRecognizedSpeech(recognizedText)
                }
            }
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Limpiar
        recognitionRequest = nil
        recognitionTask = nil
        
        // Desactivar sesión de audio
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    // MARK: - Procesamiento de Comandos
    
    /// Verifica si el texto contiene algún comando conocido
    private func containsCommand(_ text: String) -> Bool {
        let lowercasedText = text.lowercased()
        
        // Lista de prefijos de comando
        let commandPrefixes = ["buscar", "ir a", "seleccionar", "información", "ampliar", "reducir", "comenzar"]
        
        for prefix in commandPrefixes {
            if lowercasedText.contains(prefix) {
                return true
            }
        }
        
        return false
    }
    
    /// Procesa el texto reconocido para extraer comandos y parámetros
    private func processRecognizedSpeech(_ text: String) {
        let lowercasedText = text.lowercased()
        
        // Intentar identificar el tipo de comando
        var commandType: VoiceCommand.CommandType = .unknown
        var parameters: [String: Any] = [:]
        
        // Buscar comandos conocidos
        if lowercasedText.contains("buscar") {
            commandType = .search
            // Extraer el término de búsqueda (todo lo que viene después de "buscar")
            if let searchTerm = extractParameter(after: "buscar", in: lowercasedText) {
                parameters["searchTerm"] = searchTerm
            }
        } else if lowercasedText.contains("ir a") {
            commandType = .navigate
            if let destination = extractParameter(after: "ir a", in: lowercasedText) {
                parameters["destination"] = destination
            }
        } else if lowercasedText.contains("seleccionar") {
            commandType = .select
            if let item = extractParameter(after: "seleccionar", in: lowercasedText) {
                parameters["item"] = item
            }
        } else if lowercasedText.contains("información") {
            commandType = .showInfo
            if let subject = extractParameter(after: "información", in: lowercasedText) {
                parameters["subject"] = subject
            }
        } else if lowercasedText.contains("ampliar") {
            commandType = .zoomIn
        } else if lowercasedText.contains("reducir") {
            commandType = .zoomOut
        } else if lowercasedText.contains("comenzar cuestionario") {
            commandType = .startQuiz
            // Posibles parámetros: dificultad, tema, etc.
            if lowercasedText.contains("fácil") {
                parameters["difficulty"] = "easy"
            } else if lowercasedText.contains("difícil") {
                parameters["difficulty"] = "hard"
            }
        }
        
        // Crear el comando de voz
        let command = VoiceCommand(type: commandType, parameters: parameters)
        
        // Detener la escucha y notificar el comando reconocido
        stopListening()
        
        if commandType != .unknown {
            commandCallback?(.success(command))
        } else {
            commandCallback?(.failure(SpeechProcessingError.commandNotRecognized))
        }
    }
    
    /// Extrae un parámetro después de un prefijo en el texto
    private func extractParameter(after prefix: String, in text: String) -> String? {
        guard let range = text.range(of: prefix) else { return nil }
        
        let startIndex = range.upperBound
        let parameter = text[startIndex...].trimmingCharacters(in: .whitespacesAndNewlines)
        
        return parameter.isEmpty ? nil : parameter
    }
    
    // MARK: - SFSpeechRecognizerDelegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            stopListening()
            commandCallback?(.failure(SpeechProcessingError.recognitionNotAvailable))
        }
    }
}
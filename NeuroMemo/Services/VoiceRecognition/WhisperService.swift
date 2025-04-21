import Foundation
import AVFoundation
import Speech

class WhisperService: NSObject, SFSpeechRecognizerDelegate {
    static let shared = WhisperService()
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var completionHandler: ((Result<String, Error>) -> Void)?
    
    private override init() {
        // Inicializar con el reconocedor del idioma español
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
        super.init()
        self.speechRecognizer?.delegate = self
    }
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        // Verificar disponibilidad
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion(.failure(NSError(domain: "WhisperService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Reconocimiento de voz no disponible"])))
            return
        }
        
        // Solicitar permisos
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.startActualRecording(completion: completion)
                case .denied, .restricted, .notDetermined:
                    completion(.failure(NSError(domain: "WhisperService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Permiso denegado para reconocimiento de voz"])))
                @unknown default:
                    completion(.failure(NSError(domain: "WhisperService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Estado desconocido de autorización"])))
                }
            }
        }
    }
    
    private func startActualRecording(completion: @escaping (Result<String, Error>) -> Void) {
        // Detener cualquier grabación anterior
        if audioEngine.isRunning {
            stopRecording()
        }
        
        // Configurar sesión de audio
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Inicializar request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            completion(.failure(NSError(domain: "WhisperService", code: 4, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el request de reconocimiento"])))
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true // Puedes cambiar a false si solo quieres el resultado final
        
        // Guardar el completion handler
        self.completionHandler = completion
        
        // Iniciar reconocimiento
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            var isFinal = false
            
            if let result = result {
                // Procesar resultado
                let recognizedText = result.bestTranscription.formattedString
                print("Texto reconocido (parcial): \(recognizedText)") // Log para depuración
                isFinal = result.isFinal
                if isFinal {
                    self?.completionHandler?(.success(recognizedText))
                    self?.stopRecordingInternal() // Detener cuando es final
                }
            } else if let error = error {
                // Manejar error
                print("Error en recognitionTask: \(error)") // Log para depuración
                self?.completionHandler?(.failure(error))
                self?.stopRecordingInternal()
            }
            
            // Si no hay resultado ni error, o si el resultado no es final, no hacer nada aún
        }
        
        // Configurar entrada de audio
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Verificar si el formato es válido
        guard recordingFormat.sampleRate > 0 else {
            completion(.failure(NSError(domain: "WhisperService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Formato de grabación inválido"])))
            stopRecordingInternal()
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Iniciar motor de audio
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("WhisperService: Grabación iniciada") // Log para depuración
        } catch {
            completion(.failure(error))
            stopRecordingInternal()
        }
    }
    
    func stopRecording() {
        print("WhisperService: Deteniendo grabación manualmente") // Log para depuración
        stopRecordingInternal()
    }
    
    private func stopRecordingInternal() {
        // Solo detener si está corriendo
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionTask?.cancel() // Cancelar la tarea si aún está activa
        recognitionTask = nil
        recognitionRequest = nil
        completionHandler = nil // Limpiar el handler
        
        // Desactivar sesión de audio
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error al desactivar la sesión de audio: \(error)")
        }
        print("WhisperService: Grabación detenida") // Log para depuración
    }
    
    // SFSpeechRecognizerDelegate
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            print("WhisperService: Reconocimiento no disponible") // Log para depuración
            stopRecordingInternal()
            // Notificar al completionHandler si aún existe
            completionHandler?(.failure(NSError(domain: "WhisperService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Reconocimiento de voz no disponible"])))
        }
    }
}
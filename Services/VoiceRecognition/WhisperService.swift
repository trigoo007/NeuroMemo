import Foundation
import AVFoundation
import CoreML

enum WhisperError: Error {
    case modelLoadFailed
    case audioConversionFailed
    case transcriptionFailed
    case recordingFailed
    case permissionDenied
}

class WhisperService: NSObject, AVAudioRecorderDelegate {
    static let shared = WhisperService()
    
    private var audioRecorder: AVAudioRecorder?
    private var audioURL: URL?
    private var completionHandler: ((Result<String, Error>) -> Void)?
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Error al configurar la sesión de audio: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Grabación de Audio
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        // Verificar permisos
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                self.beginRecordingProcess(completion: completion)
            } else {
                DispatchQueue.main.async {
                    completion(.failure(WhisperError.permissionDenied))
                }
            }
        }
    }
    
    private func beginRecordingProcess(completion: @escaping (Result<String, Error>) -> Void) {
        self.completionHandler = completion
        
        // Crear URL temporal para grabar
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioURL = documentsPath.appendingPathComponent("whisper_recording.wav")
        
        // Configurar grabación
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            // Actualizar UI o estado para indicar que la grabación está en progreso
            print("Grabación iniciada...")
        } catch {
            completionHandler?(.failure(WhisperError.recordingFailed))
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        // La transcripción comenzará en audioRecorderDidFinishRecording
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag, let audioURL = self.audioURL {
            // Procesar el audio grabado
            transcribeAudio(from: audioURL) { [weak self] result in
                self?.completionHandler?(result)
            }
        } else {
            completionHandler?(.failure(WhisperError.recordingFailed))
        }
    }
    
    // MARK: - Transcripción con Whisper
    
    private func transcribeAudio(from url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // Implementación real con CoreML
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 1. Cargar el archivo de audio
                let audioData = try Data(contentsOf: url)
                
                // 2. Convertir audio al formato adecuado para el modelo
                guard let processedAudio = self.processAudioForWhisper(data: audioData) else {
                    throw WhisperError.audioConversionFailed
                }
                
                // 3. Cargar modelo Whisper (CoreML)
                guard let modelURL = Bundle.main.url(forResource: "WhisperModel", withExtension: "mlmodelc") else {
                    throw WhisperError.modelLoadFailed
                }
                
                let model = try MLModel(contentsOf: modelURL)
                
                // 4. Preparar entrada para el modelo
                let inputName = model.modelDescription.inputDescriptionsByName.first?.key ?? "audio"
                let inputFeatures = try MLDictionaryFeatureProvider(dictionary: [inputName: processedAudio])
                
                // 5. Realizar inferencia
                let prediction = try model.prediction(from: inputFeatures)
                
                // 6. Extraer texto transcrito
                let outputName = model.modelDescription.outputDescriptionsByName.first?.key ?? "transcription"
                guard let outputFeatures = prediction.featureValue(for: outputName),
                      let transcription = outputFeatures.stringValue else {
                    throw WhisperError.transcriptionFailed
                }
                
                // 7. Devolver resultado en hilo principal
                DispatchQueue.main.async {
                    completion(.success(transcription))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func processAudioForWhisper(data: Data) -> MLMultiArray? {
        do {
            // Crear un MLMultiArray con las dimensiones correctas para el modelo Whisper
            // NOTA: Las dimensiones exactas dependen del modelo específico
            let shape: [NSNumber] = [NSNumber(value: 80), NSNumber(value: 3000)]
            let multiArray = try MLMultiArray(shape: shape, dataType: .float32)
            
            // Aquí iría el código para:
            // 1. Decodificar el audio WAV
            // 2. Extraer características MFCC (coeficientes cepstrales en frecuencias de mel)
            // 3. Llenar el multiArray con estas características
            
            // Ejemplo simplificado de llenado (en una implementación real esto sería mucho más complejo)
            for i in 0..<80 {
                for j in 0..<3000 {
                    let index = [i, j] as [NSNumber]
                    
                    // En una implementación real, aquí se asignarían los valores MFCC reales
                    // calculados a partir de los datos de audio
                    let value = 0.0 // Placeholder
                    multiArray[index] = NSNumber(value: value)
                }
            }
            
            return multiArray
        } catch {
            print("Error al procesar audio para Whisper: \(error)")
            return nil
        }
    }
    
    // MARK: - API Simplificada
    
    func transcribeVoiceInput(durationSeconds: TimeInterval = 5.0, completion: @escaping (Result<String, Error>) -> Void) {
        startRecording { result in
            completion(result)
        }
        
        // Programar detención automática
        DispatchQueue.main.asyncAfter(deadline: .now() + durationSeconds) { [weak self] in
            self?.stopRecording()
        }
    }
}
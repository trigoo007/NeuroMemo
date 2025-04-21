import Foundation
import os.log

/// Sistema de logging para NeuroMemo
class Logger {
    // MARK: - Niveles de Log
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
        
        var osLogType: OSLogType {
            switch self {
            case .debug:
                return .debug
            case .info:
                return .info
            case .warning:
                return .default
            case .error:
                return .error
            case .critical:
                return .fault
            }
        }
    }
    
    // MARK: - Categorías de Log
    enum Category: String {
        case general = "General"
        case ui = "UI"
        case network = "Network"
        case database = "Database"
        case imageProcessing = "ImageProcessing"
        case voiceRecognition = "VoiceRecognition"
        case gameLogic = "GameLogic"
        case userActivity = "UserActivity"
        case performance = "Performance"
    }
    
    // MARK: - Propiedades
    static let shared = Logger()
    
    private let osLoggers: [Category: OSLog]
    private let dateFormatter: DateFormatter
    private let isDebugMode: Bool
    private let logToFile: Bool
    private let logFileURL: URL?
    private let logQueue = DispatchQueue(label: "com.neuromemo.logger", qos: .utility)
    
    private init() {
        // Determinar si estamos en modo debug
        #if DEBUG
        isDebugMode = true
        #else
        isDebugMode = false
        #endif
        
        // Configurar loggers por categoría
        var loggers: [Category: OSLog] = [:]
        for category in Category.allCases {
            loggers[category] = OSLog(subsystem: "com.neuromemo.app", category: category.rawValue)
        }
        self.osLoggers = loggers
        
        // Configurar formato de fecha
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Configurar logging a archivo (solo en desarrollo o si hay permisos)
        #if DEBUG
        logToFile = true
        #else
        logToFile = UserDefaults.standard.bool(forKey: "EnableFileLogging")
        #endif
        
        // Preparar URL del archivo de log
        if logToFile {
            do {
                let documentsDirectory = try FileManager.default.url(for: .documentDirectory,
                                                                    in: .userDomainMask,
                                                                    appropriateFor: nil,
                                                                    create: true)
                let fileURL = documentsDirectory.appendingPathComponent("neuromemo.log")
                logFileURL = fileURL
                
                // Crear archivo de log si no existe
                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
                }
                
                // Limitar tamaño del archivo de log
                limitLogFileSize()
            } catch {
                print("Error configurando archivo de log: \(error.localizedDescription)")
                logFileURL = nil
            }
        } else {
            logFileURL = nil
        }
    }
    
    // MARK: - Métodos de log
    
    /// Registra un mensaje de debug (solo visible en desarrollo)
    func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        if isDebugMode {
            log(message, level: .debug, category: category, file: file, function: function, line: line)
        }
    }
    
    /// Registra un mensaje informativo
    func info(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    /// Registra una advertencia
    func warning(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    /// Registra un error
    func error(_ message: String, error: Error? = nil, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .error, category: category, file: file, function: function, line: line)
    }
    
    /// Registra un error crítico
    func critical(_ message: String, error: Error? = nil, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .critical, category: category, file: file, function: function, line: line)
    }
    
    /// Registra el inicio de una operación para medición de rendimiento
    func startMeasure(id: String, description: String, category: Category = .performance) {
        let message = "INICIO: \(description)"
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "measure_\(id)")
        log(message, level: .debug, category: category)
    }
    
    /// Registra el final de una operación y calcula el tiempo transcurrido
    func endMeasure(id: String, description: String, category: Category = .performance) {
        guard let startTime = UserDefaults.standard.object(forKey: "measure_\(id)") as? TimeInterval else {
            warning("No se encontró tiempo de inicio para: \(id)", category: category)
            return
        }
        
        let endTime = Date().timeIntervalSince1970
        let elapsedTime = endTime - startTime
        let message = "FIN: \(description) - Tiempo: \(String(format: "%.4f", elapsedTime))s"
        
        log(message, level: .debug, category: category)
        UserDefaults.standard.removeObject(forKey: "measure_\(id)")
    }
    
    // MARK: - Métodos privados
    
    private func log(_ message: String, level: Level, category: Category, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fileURL = URL(fileURLWithPath: file)
        let fileName = fileURL.lastPathComponent
        
        let formattedMessage = "[\(timestamp)] [\(level.rawValue)] [\(category.rawValue)] [\(fileName):\(line)] \(message)"
        
        // Log al sistema usando os_log
        let logger = osLoggers[category] ?? OSLog.default
        os_log("%{public}@", log: logger, type: level.osLogType, formattedMessage)
        
        // Log a archivo si está habilitado
        if logToFile, let logFileURL = logFileURL {
            logQueue.async {
                let logLine = "\(formattedMessage)\n"
                if let data = logLine.data(using: .utf8) {
                    if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                }
            }
        }
    }
    
    /// Limita el tamaño del archivo de log
    private func limitLogFileSize() {
        guard let logFileURL = logFileURL else { return }
        
        logQueue.async {
            let maxFileSize = 10 * 1024 * 1024 // 10 MB
            
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: logFileURL.path)
                if let fileSize = attributes[.size] as? UInt64, fileSize > maxFileSize {
                    // Si el archivo supera el tamaño máximo, crear un backup y uno nuevo
                    let backupURL = logFileURL.deletingLastPathComponent().appendingPathComponent("neuromemo_old.log")
                    
                    // Eliminar backup anterior si existe
                    try? FileManager.default.removeItem(at: backupURL)
                    
                    // Mover archivo actual a backup
                    try FileManager.default.moveItem(at: logFileURL, to: backupURL)
                    
                    // Crear nuevo archivo
                    FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
                    
                    self.info("Archivo de log rotado por tamaño", category: .general)
                }
            } catch {
                print("Error al verificar tamaño de log: \(error.localizedDescription)")
            }
        }
    }
    
    /// Exporta los logs a un archivo para compartir
    func exportLogs(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let sourceLogFileURL = logFileURL else {
            completion(.failure(NSError(domain: "Logger", code: 1, userInfo: [NSLocalizedDescriptionKey: "No hay archivo de log disponible"])))
            return
        }
        
        logQueue.async {
            do {
                // Crear un archivo temporal para la exportación
                let tempDir = FileManager.default.temporaryDirectory
                let exportFileURL = tempDir.appendingPathComponent("neuromemo_logs_\(self.dateFormatter.string(from: Date())).txt")
                
                // Copiar contenido actual
                try FileManager.default.copyItem(at: sourceLogFileURL, to: exportFileURL)
                
                DispatchQueue.main.async {
                    completion(.success(exportFileURL))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Limpia los logs antiguos
    func clearOldLogs() {
        guard let logFileURL = logFileURL else { return }
        
        logQueue.async {
            do {
                // Mantener el archivo pero vaciar su contenido
                try "".write(to: logFileURL, atomically: true, encoding: .utf8)
                self.info("Logs antiguos eliminados", category: .general)
            } catch {
                print("Error al limpiar logs: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Extensiones

extension Logger.Category: CaseIterable {
    static var allCases: [Logger.Category] {
        return [.general, .ui, .network, .database, .imageProcessing, .voiceRecognition, .gameLogic, .userActivity, .performance]
    }
}

// MARK: - Funciones de conveniencia

/// Log de nivel debug
func logDebug(_ message: String, category: Logger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, category: category, file: file, function: function, line: line)
}

/// Log de nivel info
func logInfo(_ message: String, category: Logger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, category: category, file: file, function: function, line: line)
}

/// Log de nivel warning
func logWarning(_ message: String, category: Logger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, category: category, file: file, function: function, line: line)
}

/// Log de nivel error
func logError(_ message: String, error: Error? = nil, category: Logger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, error: error, category: category, file: file, function: function, line: line)
}

/// Log de nivel crítico
func logCritical(_ message: String, error: Error? = nil, category: Logger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.critical(message, error: error, category: category, file: file, function: function, line: line)
}
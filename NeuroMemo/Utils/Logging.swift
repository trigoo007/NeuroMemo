// Logging.swift
import Foundation
import os.log

enum LogLevel: Int {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    
    var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

class Logger {
    // Singleton
    static let shared = Logger()
    
    // Loggers por categoría
    private var loggers: [String: OSLog] = [:]
    
    // Nivel mínimo de log (se pueden filtrar mensajes por debajo de este nivel)
    var minimumLogLevel: LogLevel = .debug
    
    // Si es falso, los logs solo se enviarán a la consola en modo debug
    var logInReleaseMode = false
    
    private init() {
        // Inicializar logger principal
        loggers["default"] = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.neuromemo", category: "default")
    }
    
    // Obtener logger para una categoría específica
    private func getLogger(for category: String) -> OSLog {
        if let logger = loggers[category] {
            return logger
        }
        
        // Crear nuevo logger si no existe
        let newLogger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.neuromemo", category: category)
        loggers[category] = newLogger
        return newLogger
    }
    
    // Log con nivel, categoría y mensaje
    func log(_ level: LogLevel, category: String = "default", message: String, file: String = #file, function: String = #function, line: Int = #line) {
        // Verificar nivel mínimo
        guard level.rawValue >= minimumLogLevel.rawValue else {
            return
        }
        
        // En release, verificar configuración
        #if !DEBUG
        if !logInReleaseMode && level != .error && level != .critical {
            return
        }
        #endif
        
        // Obtener logger adecuado
        let logger = getLogger(for: category)
        
        // Formato del mensaje
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(level.description)] [\(fileName):\(line) \(function)] \(message)"
        
        // Enviar log
        os_log("%{public}@", log: logger, type: level.osLogType, logMessage)
        
        // Para logs críticos, guardar también en archivo
        if level == .critical {
            saveToFile(logMessage)
        }
    }
    
    // Métodos de conveniencia
    func debug(_ message: String, category: String = "default", file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, category: category, message: message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: String = "default", file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, category: category, message: message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: String = "default", file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, category: category, message: message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: String = "default", file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, category: category, message: message, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: String = "default", file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, category: category, message: message, file: file, function: function, line: line)
    }
    
    // Guardar log en archivo
    private func saveToFile(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let logEntry = "\(timestamp) \(message)\n"
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logFileURL = documentsDirectory.appendingPathComponent("neuromemo_critical.log")
        
        do {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                if let data = logEntry.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try logEntry.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            os_log("Error escribiendo log a archivo: %{public}@", log: getLogger(for: "logger"), type: .error, error.localizedDescription)
        }
    }
}

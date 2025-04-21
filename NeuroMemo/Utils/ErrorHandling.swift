// ErrorHandling.swift
import Foundation
import UIKit

// Tipos de errores en la aplicación
enum AppError: Error {
    case networkError(String)
    case dataError(String)
    case authError(String)
    case userError(String)
    case serverError(String)
    case unknownError(String)
    
    var description: String {
        switch self {
        case .networkError(let message):
            return "Error de red: \(message)"
        case .dataError(let message):
            return "Error de datos: \(message)"
        case .authError(let message):
            return "Error de autenticación: \(message)"
        case .userError(let message):
            return "Error del usuario: \(message)"
        case .serverError(let message):
            return "Error del servidor: \(message)"
        case .unknownError(let message):
            return "Error desconocido: \(message)"
        }
    }
    
    var isUserFacing: Bool {
        switch self {
        case .networkError, .userError, .authError:
            return true
        case .dataError, .serverError, .unknownError:
            return false
        }
    }
}

class ErrorHandler {
    // Singleton
    static let shared = ErrorHandler()
    
    // Logger
    private let logger = Logger.shared
    
    private init() {}
    
    // Manejar un error
    func handleError(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        // Convertir error a AppError si es posible
        let appError: AppError
        
        if let err = error as? AppError {
            appError = err
        } else {
            appError = .unknownError(error.localizedDescription)
        }
        
        // Registrar el error
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.error("\(appError.description) [\(fileName):\(line) \(function)]")
        
        // Mostrar al usuario si es necesario
        if appError.isUserFacing {
            showErrorToUser(appError)
        }
        
        // Informar a servicios de análisis
        reportErrorToAnalytics(appError)
    }
    
    // Mostrar error al usuario
    private func showErrorToUser(_ error: AppError) {
        DispatchQueue.main.async {
            // Obtener la ventana principal
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                
                // Crear alerta
                let alert = UIAlertController(
                    title: "Error",
                    message: error.description,
                    preferredStyle: .alert
                )
                
                // Agregar acción
                alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
                
                // Mostrar alerta
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    // Informar a servicios de análisis
    private func reportErrorToAnalytics(_ error: AppError) {
        // En una implementación real, aquí se enviaría el error a servicios como Firebase Crashlytics
        print("Error enviado a análisis: \(error.description)")
    }
    
    // Crear un error de red
    func createNetworkError(_ message: String) -> AppError {
        return .networkError(message)
    }
    
    // Crear un error de datos
    func createDataError(_ message: String) -> AppError {
        return .dataError(message)
    }
    
    // Crear un error de usuario
    func createUserError(_ message: String) -> AppError {
        return .userError(message)
    }
}

// Extensión para manejar errores en métodos asíncronos
extension Result {
    func handleError(file: String = #file, function: String = #function, line: Int = #line) {
        if case .failure(let error) = self {
            ErrorHandler.shared.handleError(error, file: file, function: function, line: line)
        }
    }
}

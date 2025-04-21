import Foundation
import SwiftUI

/// Enumeración de errores específicos de la aplicación NeuroMemo
enum NeuroMemoError: Error {
    // Errores de datos
    case dataNotFound
    case invalidData(String)
    case saveError(String)
    case loadError(String)
    case parsingError(String)
    
    // Errores de red
    case networkError(String)
    case serverError(String)
    case authenticationError
    case connectionError
    case timeoutError
    
    // Errores de permisos
    case cameraPermissionDenied
    case microphonePermissionDenied
    case photoLibraryPermissionDenied
    case notificationsPermissionDenied
    
    // Errores de la aplicación
    case featureUnavailable
    case unsupportedDevice
    case unsupportedOSVersion
    case memoryWarning
    case internalError(String)
    
    // Errores de usuario
    case invalidUserInput(String)
    case userCancelled
    
    // Errores específicos de la funcionalidad
    case imageProcessingFailed(String)
    case speechRecognitionFailed(String)
    case translationFailed(String)
    
    var localizedDescription: String {
        switch self {
        // Errores de datos
        case .dataNotFound:
            return "No se encontraron los datos solicitados."
        case .invalidData(let details):
            return "Datos inválidos: \(details)"
        case .saveError(let details):
            return "Error al guardar datos: \(details)"
        case .loadError(let details):
            return "Error al cargar datos: \(details)"
        case .parsingError(let details):
            return "Error al analizar datos: \(details)"
        
        // Errores de red
        case .networkError(let details):
            return "Error de red: \(details)"
        case .serverError(let details):
            return "Error del servidor: \(details)"
        case .authenticationError:
            return "Error de autenticación. Por favor, inicia sesión nuevamente."
        case .connectionError:
            return "No hay conexión a Internet. Verifica tu conectividad."
        case .timeoutError:
            return "La operación ha excedido el tiempo de espera. Por favor, inténtalo de nuevo."
        
        // Errores de permisos
        case .cameraPermissionDenied:
            return "No tienes permisos para usar la cámara. Puedes habilitarlos en Configuración."
        case .microphonePermissionDenied:
            return "No tienes permisos para usar el micrófono. Puedes habilitarlos en Configuración."
        case .photoLibraryPermissionDenied:
            return "No tienes permisos para acceder a la biblioteca de fotos. Puedes habilitarlos en Configuración."
        case .notificationsPermissionDenied:
            return "Las notificaciones están desactivadas. Puedes habilitarlas en Configuración."
        
        // Errores de la aplicación
        case .featureUnavailable:
            return "Esta función no está disponible en este momento."
        case .unsupportedDevice:
            return "Tu dispositivo no es compatible con esta característica."
        case .unsupportedOSVersion:
            return "Esta característica requiere una versión más reciente del sistema operativo."
        case .memoryWarning:
            return "Memoria insuficiente. Cierra algunas aplicaciones e inténtalo de nuevo."
        case .internalError(let details):
            return "Error interno: \(details)"
        
        // Errores de usuario
        case .invalidUserInput(let details):
            return "Entrada inválida: \(details)"
        case .userCancelled:
            return "Operación cancelada por el usuario."
        
        // Errores específicos de la funcionalidad
        case .imageProcessingFailed(let details):
            return "Error al procesar la imagen: \(details)"
        case .speechRecognitionFailed(let details):
            return "Error en el reconocimiento de voz: \(details)"
        case .translationFailed(let details):
            return "Error en la traducción: \(details)"
        }
    }
    
    var suggestedAction: String? {
        switch self {
        case .dataNotFound:
            return "Intenta reiniciar la aplicación o reinstalarla si el problema persiste."
        case .connectionError:
            return "Verifica tu conexión Wi-Fi o datos móviles."
        case .authenticationError:
            return "Inicia sesión nuevamente."
        case .cameraPermissionDenied, .microphonePermissionDenied, .photoLibraryPermissionDenied, .notificationsPermissionDenied:
            return "Ve a Configuración > NeuroMemo > Permisos para habilitar el acceso."
        case .memoryWarning:
            return "Cierra aplicaciones en segundo plano e inténtalo de nuevo."
        default:
            return nil
        }
    }
    
    var isUserFacing: Bool {
        switch self {
        case .internalError:
            return false
        default:
            return true
        }
    }
    
    var shouldLog: Bool {
        return true
    }
}

/// Clase para manejar errores en la aplicación
class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    /// Registra el error y muestra una alerta si es necesario
    func handle(_ error: Error, file: String = #file, line: Int = #line, function: String = #function) {
        let neuroError: NeuroMemoError
        
        // Convertir errores estándar a NeuroMemoError si es necesario
        if let error = error as? NeuroMemoError {
            neuroError = error
        } else {
            neuroError = .internalError(error.localizedDescription)
        }
        
        // Registrar el error
        if neuroError.shouldLog {
            logError(neuroError, file: file, line: line, function: function)
        }
    }
    
    /// Registra el error en el sistema de logs
    private func logError(_ error: NeuroMemoError, file: String, line: Int, function: String) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let message = "[\(fileName):\(line) - \(function)] \(error.localizedDescription)"
        
        // Registrar en el sistema de logs
        Logger.log(.error, message)
        
        // En desarrollo, imprimir en consola
        #if DEBUG
        print("ERROR: \(message)")
        if let action = error.suggestedAction {
            print("ACCIÓN SUGERIDA: \(action)")
        }
        #endif
    }
    
    /// Crea una vista de alerta para el error especificado
    func createErrorAlert(for error: Error, onDismiss: (() -> Void)? = nil) -> Alert {
        let neuroError: NeuroMemoError
        
        if let error = error as? NeuroMemoError {
            neuroError = error
        } else {
            neuroError = .internalError(error.localizedDescription)
        }
        
        var actions = [Alert.Button]()
        
        // Botón de acción sugerida si existe
        if let actionText = neuroError.suggestedAction {
            actions.append(.default(Text("Solucionar"), action: {
                // Aquí se podría implementar una acción específica según el tipo de error
                onDismiss?()
            }))
        }
        
        // Siempre añadir un botón para cerrar
        actions.append(.cancel(Text("Cerrar"), action: {
            onDismiss?()
        }))
        
        return Alert(
            title: Text("Error"),
            message: Text(neuroError.localizedDescription),
            primaryButton: actions.count > 1 ? actions[0] : .cancel(Text("Cerrar"), action: { onDismiss?() }),
            secondaryButton: actions.count > 1 ? actions[1] : .cancel(Text(""))
        )
    }
    
    /// Envía el error a un servicio de monitoreo (implementación ficticia)
    func reportToMonitoring(_ error: Error, userInfo: [String: Any]? = nil) {
        // Implementación para enviar el error a un servicio de monitoreo como Firebase Crashlytics
        // Esto sería implementado en una versión real con el SDK correspondiente
        #if DEBUG
        print("Reportando error a monitoreo: \(error.localizedDescription)")
        if let userInfo = userInfo {
            print("Información adicional: \(userInfo)")
        }
        #endif
    }
}

/// Vista modificadora para manejar errores en SwiftUI
struct ErrorHandlingViewModifier: ViewModifier {
    @Binding var error: Error?
    var onDismiss: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(item: Binding<IdentifiableError?>(
                get: { error != nil ? IdentifiableError(error: error!) : nil },
                set: { error = $0?.error }
            )) { identifiableError in
                ErrorHandler.shared.createErrorAlert(for: identifiableError.error, onDismiss: onDismiss)
            }
    }
}

/// Estructura para hacer que los errores sean identificables para SwiftUI
struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: Error
}

extension View {
    /// Añade manejo de errores a una vista
    func handleError(error: Binding<Error?>, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(ErrorHandlingViewModifier(error: error, onDismiss: onDismiss))
    }
}
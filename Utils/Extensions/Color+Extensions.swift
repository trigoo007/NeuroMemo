import SwiftUI

extension Color {
    /// Inicializa un color a partir de valores hexadecimales
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Convierte un color a su representación hexadecimal
    var toHex: String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
    
    /// Crea una versión más clara del color
    func lighten(by percentage: CGFloat = 0.3) -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return self
        }
        
        return Color(
            red: min(red + percentage, 1.0),
            green: min(green + percentage, 1.0),
            blue: min(blue + percentage, 1.0),
            opacity: alpha
        )
    }
    
    /// Crea una versión más oscura del color
    func darken(by percentage: CGFloat = 0.3) -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return self
        }
        
        return Color(
            red: max(red - percentage, 0.0),
            green: max(green - percentage, 0.0),
            blue: max(blue - percentage, 0.0),
            opacity: alpha
        )
    }
    
    /// Comprueba si el color es oscuro (útil para determinar si usar texto blanco o negro encima)
    var isDark: Bool {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Fórmula YIQ para determinar si un color es oscuro
        let yiq = ((red * 299) + (green * 587) + (blue * 114)) / 1000
        
        return yiq < 0.5
    }
    
    /// Devuelve blanco o negro dependiendo de qué color tenga mejor contraste con el color actual
    var contrastingTextColor: Color {
        return self.isDark ? .white : .black
    }
    
    /// Colores temáticos para la aplicación NeuroMemo
    static let neuroBlue = Color(hex: "3485FF")
    static let neuroDeepBlue = Color(hex: "0A4DA6")
    static let neroLightBlue = Color(hex: "7CB2FF")
    static let neuroRed = Color(hex: "FF4757")
    static let neuroGray = Color(hex: "505D72")
    static let neuroLightGray = Color(hex: "D9E2EC")
    
    /// Colores para áreas específicas del cerebro
    static let neuroCerebrum = Color(hex: "FF6B6B")
    static let neuroCerebellum = Color(hex: "4ECDC4")
    static let neuroBrainstem = Color(hex: "FFD166")
    static let neuroCranialNerves = Color(hex: "6A89CC")
    static let neuroVascular = Color(hex: "E84545")
    static let neuroVentricular = Color(hex: "577590")
    
    /// Colores para niveles de dificultad
    static let difficultyBeginner = Color(hex: "4CAF50")
    static let difficultyEasy = Color(hex: "8BC34A")
    static let difficultyMedium = Color(hex: "FFC107")
    static let difficultyHard = Color(hex: "FF9800")
    static let difficultyExpert = Color(hex: "F44336")
    
    /// Genera un color para una estructura anatómica basado en su nombre
    static func colorForStructure(named name: String) -> Color {
        // Determinar el sistema basado en palabras clave en el nombre
        let lowercaseName = name.lowercased()
        
        if lowercaseName.contains("corteza") || lowercaseName.contains("cortical") || lowercaseName.contains("cerebr") {
            return .neuroCerebrum
        } else if lowercaseName.contains("cerebelo") || lowercaseName.contains("cerebel") {
            return .neuroCerebellum
        } else if lowercaseName.contains("tronco") || lowercaseName.contains("bulbo") || lowercaseName.contains("puente") || lowercaseName.contains("mesencéfalo") {
            return .neuroBrainstem
        } else if lowercaseName.contains("nervio") || lowercaseName.contains("craneal") {
            return .neuroCranialNerves
        } else if lowercaseName.contains("arter") || lowercaseName.contains("ven") || lowercaseName.contains("vaso") || lowercaseName.contains("sanguin") {
            return .neuroVascular
        } else if lowercaseName.contains("ventrículo") || lowercaseName.contains("ventricular") || lowercaseName.contains("líquido") {
            return .neuroVentricular
        }
        
        // Color por defecto basado en el hash del nombre
        let hash = abs(name.hash)
        let hue = Double(hash % 1000) / 1000.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.9)
    }
    
    /// Color para un nivel de dificultad
    static func colorForDifficulty(_ level: DifficultyManager.DifficultyLevel) -> Color {
        switch level {
        case .beginner:
            return .difficultyBeginner
        case .easy:
            return .difficultyEasy
        case .medium:
            return .difficultyMedium
        case .hard:
            return .difficultyHard
        case .expert:
            return .difficultyExpert
        }
    }
}
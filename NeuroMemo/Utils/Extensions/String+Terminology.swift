// String+Terminology.swift
import Foundation
import NaturalLanguage

extension String {
    // Normalizar término anatómico (eliminar acentos, minúsculas)
    func normalizedAnatomicalTerm() -> String {
        // Convertir a minúsculas
        let lowercased = self.lowercased()
        
        // Eliminar acentos
        return lowercased.folding(options: .diacriticInsensitive, locale: .current)
    }
    
    // Extraer términos anatómicos potenciales
    func extractAnatomicalTerms() -> [String] {
        let anatomicalKeywords = [
            "cerebro", "cerebelo", "hipocampo", "tálamo", "hipotálamo", "médula",
            "nervio", "neurona", "axón", "dendrita", "sinapsis", "ganglio",
            "corteza", "lóbulo", "giro", "surco", "ventrículos", "meninges",
            "dura", "aracnoides", "piamadre", "líquido", "cefalorraquídeo",
            "corazón", "arteria", "vena", "capilares", "sangre", "miocardio",
            "endocardio", "pericardio", "válvula", "aorta", "pulmonar",
            "pulmón", "bronquio", "alveolo", "pleura", "diafragma", "tráquea",
            "laringe", "faringe", "esófago", "estómago", "intestino", "hígado",
            "páncreas", "bazo", "vesícula", "riñón", "uréter", "vejiga", "uretra",
            "glándula", "tiroides", "hipófisis", "suprarrenal", "gónada"
        ]
        
        // Tokenizar el texto
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = self
        
        var terms: [String] = []
        
        tokenizer.enumerateTokens(in: self.startIndex..<self.endIndex) { tokenRange, _ in
            let token = String(self[tokenRange]).lowercased()
            
            // Verificar si el token es un término anatómico conocido
            if anatomicalKeywords.contains(token) {
                terms.append(token)
            }
            
            return true
        }
        
        // Buscar también términos compuestos
        for keyword in anatomicalKeywords {
            if keyword.contains(" ") && self.lowercased().contains(keyword) {
                terms.append(keyword)
            }
        }
        
        return terms
    }
    
    // Validar si es un término anatómico
    func isAnatomicalTerm() -> Bool {
        let anatomicalPrefixes = ["neuro", "cardio", "hepat", "gastro", "pulmon", "nefro", "osteo", "arterio", "veno"]
        let anatomicalSuffixes = ["itis", "algia", "patía", "oma", "osis", "ectomía", "tomía", "plastia"]
        
        let normalized = self.normalizedAnatomicalTerm()
        
        // Verificar prefijos
        for prefix in anatomicalPrefixes {
            if normalized.hasPrefix(prefix) {
                return true
            }
        }
        
        // Verificar sufijos
        for suffix in anatomicalSuffixes {
            if normalized.hasSuffix(suffix) {
                return true
            }
        }
        
        // Verificar contra lista de términos anatómicos conocidos
        return !self.extractAnatomicalTerms().isEmpty
    }
    
    // Obtener forma latina del término
    func latinForm() -> String? {
        let spanishToLatin: [String: String] = [
            "cerebro": "cerebrum",
            "cerebelo": "cerebellum",
            "hipocampo": "hippocampus",
            "tálamo": "thalamus",
            "hipotálamo": "hypothalamus",
            "médula": "medulla",
            "nervio": "nervus",
            "neurona": "neuron",
            "corazón": "cor",
            "arteria": "arteria",
            "vena": "vena",
            "pulmón": "pulmo",
            "estómago": "ventriculus",
            "intestino": "intestinum",
            "hígado": "hepar",
            "riñón": "ren",
            "hueso": "os",
            "músculo": "musculus"
        ]
        
        return spanishToLatin[self.lowercased()]
    }
    
    // Obtener variantes del término
    func getAnatomicalVariants() -> [String] {
        var variants = [self]
        
        // Agregar forma normalizada
        let normalized = self.normalizedAnatomicalTerm()
        if normalized != self.lowercased() {
            variants.append(normalized)
        }
        
        // Agregar forma latina si existe
        if let latin = self.latinForm() {
            variants.append(latin)
        }
        
        // Agregar formas alternativas comunes
        switch self.lowercased() {
        case "cerebro":
            variants.append("encéfalo")
        case "médula espinal":
            variants.append("médula")
            variants.append("médula raquídea")
        case "corazón":
            variants.append("miocardio")
        case "estómago":
            variants.append("estomago")
        default:
            break
        }
        
        return variants
    }
    
    // Detectar si un texto contiene términos anatómicos
    func containsAnatomicalTerms() -> Bool {
        return !self.extractAnatomicalTerms().isEmpty
    }
}

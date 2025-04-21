import SwiftUI
import Combine

class StudyViewModel: ObservableObject {
    @Published var selectedSystem: String?
    @Published var selectedLevels: [Int] = []
    @Published var filteredItems: [StudyItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // Datos del sistema
    var availableSystems: [String] = []
    var dataManager: DataManager?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // No cargar datos aquí, esperar a que se inyecte dataManager
    }
    
    func updateFilteredItems() {
        guard let dataManager = self.dataManager else {
            self.error = NSError(
                domain: "StudyViewModel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "DataManager no disponible"]
            )
            return
        }
        
        isLoading = true
        
        // Cargar sistemas disponibles
        if availableSystems.isEmpty {
            availableSystems = dataManager.getAllSystems()
        }
        
        // Filtrar estructuras
        var structures = dataManager.knowledgeBase.structures
        
        if let system = selectedSystem {
            structures = structures.filter { $0.system == system }
        }
        
        if !selectedLevels.isEmpty {
            structures = structures.filter { selectedLevels.contains($0.level) }
        }
        
        // Mapear a StudyItems
        self.filteredItems = structures.map { structure in
            StudyItem(
                id: structure.id,
                title: structure.name,
                subtitle: structure.system,
                type: .structure,
                imageURL: structure.imageReferences?.first,
                progress: structure.userFamiliarity,
                tags: structure.tags ?? [],
                lastStudied: structure.lastStudied
            )
        }
        
        isLoading = false
    }
    
    func filteredItems(searchText: String) -> [StudyItem] {
        if searchText.isEmpty {
            return filteredItems
        }
        
        let searchTerms = searchText.lowercased().components(separatedBy: " ")
        
        return filteredItems.filter { item in
            let itemText = "\(item.title) \(item.subtitle) \(item.tags.joined(separator: " "))".lowercased()
            
            return searchTerms.allSatisfy { term in
                itemText.contains(term)
            }
        }
    }
    
    func getRelatedStructures(ids: [String]) -> [AnatomicalStructure] {
        guard let dataManager = self.dataManager else { return [] }
        
        return ids.compactMap { id in
            dataManager.getStructureById(id)
        }
    }
    
    func recordStudySession(for structureId: String) {
        guard let dataManager = self.dataManager else { return }
        
        // Registrar sesión (por defecto 5 minutos)
        dataManager.recordStudySession(structureId: structureId, duration: 300)
        
        // Incrementar familiaridad con la estructura
        dataManager.updateStructureFamiliarity(structureId: structureId, increment: 0.1)
        
        // Actualizar la UI
        updateFilteredItems()
    }
}

// Modelo para elementos de estudio (usado para mostrar en las listas)
struct StudyItem: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var type: StudyItemType
    var imageURL: String?
    var progress: Double
    var tags: [String]
    var lastStudied: Date?
    
    var formattedLastStudied: String {
        guard let date = lastStudied else {
            return "No estudiado"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    enum StudyItemType {
        case structure
        case image
        case note
    }
}

// Vista para el quiz rápido
struct QuickQuizView: View {
    let structure: AnatomicalStructure
    @State private var currentQuestion = 0
    @State private var score = 0
    @State private var showingResult = false
    
    let questions: [QuizQuestion] = [
        QuizQuestion(
            text: "¿A qué sistema pertenece esta estructura?",
            options: ["Sistema Nervioso Central", "Sistema Cardiovascular", "Sistema Musculoesquelético", "Sistema Digestivo"],
            correctIndex: 0
        ),
        QuizQuestion(
            text: "¿Cuál de estas NO es una función de esta estructura?",
            options: ["Procesamiento cognitivo", "Producción de hormonas", "Integración sensorial", "Control motor"],
            correctIndex: 1
        ),
        QuizQuestion(
            text: "¿En qué nivel de organización se encuentra esta estructura?",
            options: ["Nivel 1 (Básico)", "Nivel 2 (Intermedio)", "Nivel 3 (Avanzado)", "Nivel 4 (Especializado)"],
            correctIndex: 2
        ),
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            if showingResult {
                // Mostrar resultado
                Text("Quiz completado")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Puntuación: \(score)/\(questions.count)")
                    .font(.title2)
                
                Image(systemName: score > questions.count / 2 ? "star.fill" : "star")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .padding()
                
                Button("Cerrar") {
                    // Cerrar la vista
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 20)
                
            } else {
                // Mostrar pregunta
                Text("Pregunta \(currentQuestion + 1) de \(questions.count)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(questions[currentQuestion].text)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding()
                
                ForEach(0..<questions[currentQuestion].options.count, id: \.self) { index in
                    Button(action: {
                        checkAnswer(index)
                    }) {
                        Text(questions[currentQuestion].options[index])
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Quiz Rápido")
    }
    
    private func checkAnswer(_ selectedIndex: Int) {
        if selectedIndex == questions[currentQuestion].correctIndex {
            score += 1
        }
        
        if currentQuestion < questions.count - 1 {
            currentQuestion += 1
        } else {
            showingResult = true
        }
    }
}

struct QuizQuestion {
    let text: String
    let options: [String]
    let correctIndex: Int
} 
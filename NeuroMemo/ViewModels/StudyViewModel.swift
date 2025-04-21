import Foundation
import Combine

class StudyViewModel: ObservableObject {
    // Estado publicado
    @Published var selectedSystem: AnatomicalSystem?
    @Published var selectedLevels: [AnatomicalLevel] = []
    @Published var selectedModalities: [ImageModality] = []
    @Published var selectedDifficulty: Int?
    @Published var filteredItems: [StudyItem] = []
    @Published var isLoading = false
    @Published var isListening = false
    
    // Servicios
    private var dataManager: DataManager?
    private var cancellables = Set<AnyCancellable>()
    
    // Inicializador
    init(dataManager: DataManager? = nil) {
        self.dataManager = dataManager
        setupSubscriptions()
    }
    
    // Configurar suscripciones a cambios
    private func setupSubscriptions() {
        // Observar cambios en filtros y actualizar elementos filtrados
        $selectedSystem
            .combineLatest($selectedLevels, $selectedModalities, $selectedDifficulty)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFilteredItems()
            }
            .store(in: &cancellables)
    }
    
    // Actualizar elementos filtrados
    private func updateFilteredItems() {
        // Implementación inicial - aquí filtrarías los datos reales
        isLoading = true
        
        // Simular carga
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Aquí implementarías la lógica real de filtrado
            self.filteredItems = self.createSampleItems()
            self.isLoading = false
        }
    }
    
    // Filtrar elementos por texto de búsqueda
    func filterItems(searchText: String) -> [StudyItem] {
        if searchText.isEmpty {
            return filteredItems
        }
        
        // Filtrar por texto
        return filteredItems.filter { item in
            return item.title.lowercased().contains(searchText.lowercased()) ||
                   item.subtitle.lowercased().contains(searchText.lowercased()) ||
                   item.tags.contains { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    // Resetear filtros
    func resetFilters() {
        selectedSystem = nil
        selectedLevels = []
        selectedModalities = []
        selectedDifficulty = nil
    }
    
    // Alternar reconocimiento de voz
    func toggleVoiceRecognition() {
        isListening.toggle()
        // Aquí conectarías con WhisperService
    }
    
    // Crear elementos de muestra
    private func createSampleItems() -> [StudyItem] {
        // Implementación inicial con datos de ejemplo
        var items: [StudyItem] = []
        
        // Aquí crearías elementos de muestra
        // Por ejemplo:
        let item = StudyItem(
            id: UUID(),
            title: "Corteza Prefrontal",
            subtitle: "Lóbulo Frontal",
            type: .structure,
            imageURL: "corteza_prefrontal",
            progress: 0.65,
            tags: ["corteza", "frontal", "cognición"],
            lastStudied: Date().addingTimeInterval(-7 * 86400)
        )
        
        items.append(item)
        
        return items
    }
}

// Definición de StudyItem
struct StudyItem: Identifiable {
    var id: UUID
    var title: String
    var subtitle: String
    var type: StudyItemType
    var imageURL: String?
    var progress: Double?
    var tags: [String]
    var lastStudied: Date?
}

enum StudyItemType {
    case structure
    case image
    case collection
}

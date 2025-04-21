import Foundation
import Combine

class StudyViewModel: ObservableObject {
    // Estado publicado
    @Published var selectedSystem: String? // Cambiado de AnatomicalSystem a String
    @Published var selectedLevels: [Int] = [] // Cambiado de [AnatomicalLevel] a [Int]
    // @Published var selectedModalities: [ImageModality] = [] // Comentado o eliminar si ImageModality no está definido
    @Published var selectedDifficulty: Int?
    @Published var filteredItems: [StudyItem] = []
    @Published var isLoading = false
    @Published var isListening = false

    // Servicios
    private let dataManager: DataManager
    private let knowledgeBase: KnowledgeBase // Añadido KnowledgeBase
    private var cancellables = Set<AnyCancellable>()

    // Inicializador con inyección de dependencias
    init(dataManager: DataManager = DataManager.shared, knowledgeBase: KnowledgeBase = KnowledgeBase.shared) {
        self.dataManager = dataManager
        self.knowledgeBase = knowledgeBase // Asignar knowledgeBase
        setupSubscriptions()
        updateFilteredItems() // Cargar datos iniciales
    }

    // Configurar suscripciones a cambios
    private func setupSubscriptions() {
        // Observar cambios en filtros y actualizar elementos filtrados
        $selectedSystem
            .combineLatest($selectedLevels, /*$selectedModalities,*/ $selectedDifficulty) // Ajustado combineLatest
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFilteredItems()
            }
            .store(in: &cancellables)
    }

    // Actualizar elementos filtrados
    private func updateFilteredItems() {
        isLoading = true

        // Usar knowledgeBase para obtener las estructuras
        var structures = knowledgeBase.structures

        // Aplicar filtros
        if let system = selectedSystem {
            structures = structures.filter { $0.system == system }
        }
        if !selectedLevels.isEmpty {
            structures = structures.filter { selectedLevels.contains($0.level) }
        }
        if let difficulty = selectedDifficulty {
            structures = structures.filter { $0.difficulty == difficulty }
        }
        // Añadir filtro por selectedModalities si es necesario

        // Mapear a StudyItem
        self.filteredItems = structures.map { structure in
            StudyItem(
                id: structure.id, // Usar String ID
                title: structure.name,
                subtitle: structure.system,
                type: .structure,
                imageURL: structure.imageReferences?.first, // Usar primera imagen como referencia
                progress: structure.userFamiliarity, // Usar familiaridad como progreso
                tags: structure.tags ?? [],
                lastStudied: structure.lastStudied
            )
        }

        isLoading = false
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
        // selectedModalities = [] // Comentado o eliminar si ImageModality no está definido
        selectedDifficulty = nil
    }
    
    // Alternar reconocimiento de voz
    func toggleVoiceRecognition() {
        isListening.toggle()
        // Aquí conectarías con WhisperService
    }
    
    // Crear elementos de muestra (ya no es necesario si updateFilteredItems carga datos reales)
    /*
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
    */
}

// Definición de StudyItem (ajustar ID a String)
struct StudyItem: Identifiable {
    var id: String // Cambiado de UUID a String
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

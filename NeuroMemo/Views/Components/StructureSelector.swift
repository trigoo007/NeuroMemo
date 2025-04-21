// StructureSelector.swift
import SwiftUI

struct StructureSelector: View {
    @Binding var selectedStructure: AnatomicalStructure?
    let structures: [AnatomicalStructure]
    let selectionMode: SelectionMode
    
    enum SelectionMode {
        case single
        case multiple
    }
    
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var multipleSelections: Set<String> = []
    
    var categories: [String] {
        Array(Set(structures.map { $0.category })).sorted()
    }
    
    var filteredStructures: [AnatomicalStructure] {
        var filtered = structures
        
        // Filtrar por categoría si hay una seleccionada
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filtrar por texto de búsqueda
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.description.lowercased().contains(searchText.lowercased())
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack {
            // Barra de búsqueda
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Buscar estructura", text: $searchText)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Selector de categorías
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CategoryButton(
                        title: "Todas",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(categories, id: \.self) { category in
                        CategoryButton(
                            title: category,
                            isSelected: selectedCategory == category,
                            action: {
                                if selectedCategory == category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Lista de estructuras
            List {
                ForEach(filteredStructures) { structure in
                    StructureRow(
                        structure: structure,
                        isSelected: selectionMode == .single
                            ? selectedStructure?.id == structure.id
                            : multipleSelections.contains(structure.id)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        switch selectionMode {
                        case .single:
                            selectedStructure = structure
                        case .multiple:
                            if multipleSelections.contains(structure.id) {
                                multipleSelections.remove(structure.id)
                            } else {
                                multipleSelections.insert(structure.id)
                            }
                        }
                    }
                }
            }
            
            // Botones de acción (solo para selección múltiple)
            if selectionMode == .multiple {
                HStack {
                    Button("Cancelar") {
                        multipleSelections.removeAll()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Seleccionar (\(multipleSelections.count))") {
                        // Aquí iría la acción para procesar las selecciones múltiples
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(multipleSelections.isEmpty)
                }
                .padding()
            }
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct StructureRow: View {
    let structure: AnatomicalStructure
    let isSelected: Bool
    
    var body: some View {
        HStack {
            if let imageURL = structure.imageURLs.first {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(structure.name)
                    .font(.headline)
                
                Text(structure.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
    }
}

import SwiftUI

struct StructureInfoView: View {
    let structure: AnatomicalStructure
    @ObservedObject var viewModel: StudyViewModel
    @State private var showingQuiz = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Imagen de la estructura
                if let imageURLs = structure.imageReferences, let firstURL = imageURLs.first {
                    AsyncImage(url: URL(string: firstURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.2))
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                }
                
                // Nombre y categoría
                Text(structure.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                if let category = structure.category {
                    Text(category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text(structure.system)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Tabs para contenido
                Picker("Sección", selection: $selectedTab) {
                    Text("Información").tag(0)
                    Text("Funciones").tag(1)
                    Text("Relaciones").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 8)
                
                // Contenido según la pestaña seleccionada
                Group {
                    if selectedTab == 0 {
                        // Información básica
                        VStack(alignment: .leading, spacing: 12) {
                            InfoSection(title: "Descripción", content: structure.description)
                            
                            if let latinName = structure.latinName {
                                InfoSection(title: "Nombre latino", content: latinName)
                            }
                            
                            if let synonyms = structure.synonyms, !synonyms.isEmpty {
                                InfoSection(title: "Sinónimos", content: synonyms.joined(separator: ", "))
                            }
                            
                            if let tags = structure.tags, !tags.isEmpty {
                                TagsView(tags: tags)
                            }
                        }
                    } else if selectedTab == 1 {
                        // Funciones
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Funciones")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            if let functions = structure.functions, !functions.isEmpty {
                                ForEach(functions, id: \.self) { function in
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text(function)
                                    }
                                }
                            } else if let roles = structure.functionalRoles, !roles.isEmpty {
                                ForEach(roles, id: \.self) { role in
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text(role)
                                    }
                                }
                            } else {
                                Text("No hay información disponible sobre las funciones de esta estructura.")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                            
                            if let clinical = structure.clinicalRelevance {
                                InfoSection(title: "Relevancia clínica", content: clinical)
                            }
                        }
                    } else {
                        // Relaciones con otras estructuras
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Estructuras relacionadas")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            if let relatedIDs = structure.relatedStructures, !relatedIDs.isEmpty {
                                let relatedStructures = viewModel.getRelatedStructures(ids: relatedIDs)
                                if !relatedStructures.isEmpty {
                                    ForEach(relatedStructures) { related in
                                        RelatedStructureRow(structure: related)
                                    }
                                } else {
                                    Text("No se encontraron estructuras relacionadas.")
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            } else {
                                Text("No hay información disponible sobre estructuras relacionadas.")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                }
                .padding(.top, 8)
                
                // Botones de acciones
                HStack {
                    Button(action: {
                        viewModel.recordStudySession(for: structure.id)
                    }) {
                        Label("Marcar como estudiado", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button(action: {
                        showingQuiz = true
                    }) {
                        Label("Quiz rápido", systemImage: "questionmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.top, 24)
            }
            .padding()
        }
        .sheet(isPresented: $showingQuiz) {
            QuickQuizView(structure: structure)
        }
    }
}

struct InfoSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.body)
        }
    }
}

struct TagsView: View {
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Etiquetas")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct RelatedStructureRow: View {
    let structure: AnatomicalStructure
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(structure.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(structure.system)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.purple.opacity(0.15))
            .foregroundColor(.purple)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
} 
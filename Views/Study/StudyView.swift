import SwiftUI

struct StudyView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var viewModel = StudyViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedStructure: AnatomicalStructure?
    
    var body: some View {
        ZStack {
            // Fondo con gradiente suave
            LinearGradient(
                gradient: Gradient(colors: [Color(UIColor.systemGray6), Color(UIColor.systemBackground)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Barra de búsqueda
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Buscar estructuras o imágenes...", text: $searchText)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        showingFilters.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle\(showingFilters ? ".fill" : "")")
                            .foregroundColor(.purple)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Contenedor de filtros
                if showingFilters {
                    FilterView(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.horizontal)
                }
                
                // Lista de estructuras filtradas
                List {
                    ForEach(viewModel.filteredItems(searchText: searchText)) { item in
                        StudyItemRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedStructure = dataManager.getStructureById(item.id)
                            }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    viewModel.updateFilteredItems()
                }
            }
        }
        .navigationTitle("Estudio")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedStructure) { structure in
            NavigationView {
                StructureInfoView(structure: structure, viewModel: viewModel)
                    .navigationBarTitle(structure.name, displayMode: .inline)
                    .navigationBarItems(trailing: Button("Cerrar") {
                        selectedStructure = nil
                    })
            }
        }
        .onAppear {
            // Asegurarse de que el viewModel tiene la referencia al dataManager
            viewModel.dataManager = dataManager
            viewModel.updateFilteredItems()
        }
    }
}

struct FilterView: View {
    @ObservedObject var viewModel: StudyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filtrar por sistema:")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.availableSystems, id: \.self) { system in
                        FilterChip(
                            title: system,
                            isSelected: viewModel.selectedSystem == system,
                            action: {
                                if viewModel.selectedSystem == system {
                                    viewModel.selectedSystem = nil
                                } else {
                                    viewModel.selectedSystem = system
                                }
                                viewModel.updateFilteredItems()
                            }
                        )
                    }
                }
            }
            
            Text("Filtrar por nivel:")
                .font(.headline)
                .padding(.top, 8)
            
            HStack {
                ForEach(1...5, id: \.self) { level in
                    FilterChip(
                        title: "Nivel \(level)",
                        isSelected: viewModel.selectedLevels.contains(level),
                        action: {
                            if viewModel.selectedLevels.contains(level) {
                                viewModel.selectedLevels.removeAll { $0 == level }
                            } else {
                                viewModel.selectedLevels.append(level)
                            }
                            viewModel.updateFilteredItems()
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .animation(.easeInOut, value: viewModel.selectedSystem)
        .animation(.easeInOut, value: viewModel.selectedLevels)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.purple : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct StudyItemRow: View {
    let item: StudyItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Imagen o icono
            if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "brain")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                        .foregroundColor(.purple)
                }
                .frame(width: 60, height: 60)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            } else {
                Image(systemName: "brain")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(12)
                    .frame(width: 60, height: 60)
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Tags
                if !item.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(item.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Indicador de progreso
            CircularProgressView(progress: item.progress)
                .frame(width: 30, height: 30)
        }
        .padding(.vertical, 4)
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.gray.opacity(0.3),
                    lineWidth: 3
                )
            
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round
                    )
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: progress)
        }
    }
}

struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StudyView()
                .environmentObject(DataManager())
        }
    }
} 
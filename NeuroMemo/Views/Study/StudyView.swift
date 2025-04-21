import SwiftUI

struct StudyView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var viewModel = StudyViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    
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
                
                // Contenido principal (aquí irá el contenido real)
                Text("Contenido del estudio")
                    .font(.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Estudio")
    }
}

struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        StudyView()
            .environmentObject(DataManager())
    }
}

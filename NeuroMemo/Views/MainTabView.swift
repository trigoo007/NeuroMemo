import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Pestaña de Estudio
            NavigationView {
                StudyView()
            }
            .tabItem {
                Label("Estudio", systemImage: "book.fill")
            }
            .tag(0)
            
            // Pestaña de Juegos
            NavigationView {
                GameSelectorView()
            }
            .tabItem {
                Label("Juegos", systemImage: "gamecontroller.fill")
            }
            .tag(1)
            
            // Pestaña de Biblioteca
            NavigationView {
                LibraryView()
            }
            .tabItem {
                Label("Biblioteca", systemImage: "photo.on.rectangle")
            }
            .tag(2)
            
            // Pestaña de Perfil
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.fill")
            }
            .tag(3)
        }
        .accentColor(.purple)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(DataManager())
    }
}

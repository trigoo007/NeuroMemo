import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Pestaña de Estudio
            NavigationView {
                StudyView()
                    .environmentObject(dataManager)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Estudio", systemImage: "book.fill")
            }
            .tag(0)
            
            // Pestaña de Juegos
            NavigationView {
                GameSelectorView()
                    .environmentObject(dataManager)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Juegos", systemImage: "gamecontroller.fill")
            }
            .tag(1)
            
            // Pestaña de Biblioteca
            NavigationView {
                LibraryView()
                    .environmentObject(dataManager)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Biblioteca", systemImage: "photo.on.rectangle")
            }
            .tag(2)
            
            // Pestaña de Perfil
            NavigationView {
                ProfileView()
                    .environmentObject(dataManager)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Perfil", systemImage: "person.fill")
            }
            .tag(3)
        }
        .accentColor(.purple)
        .onAppear {
            // Configurar la apariencia de la barra de navegación para toda la app
            setupAppearance()
        }
    }
    
    private func setupAppearance() {
        // Configurar NavigationBar para toda la app
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Configurar TabBar para toda la app
        UITabBar.appearance().tintColor = UIColor.systemPurple
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(DataManager())
    }
} 
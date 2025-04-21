// ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Perfil")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.trailing, 10)
                        
                        VStack(alignment: .leading) {
                            TextField("Nombre de usuario", text: $viewModel.username)
                                .font(.headline)
                            
                            Text("Estudiando desde: \(viewModel.formattedStartDate)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Progreso")) {
                    HStack {
                        VStack {
                            Text("\(viewModel.studiedStructuresCount)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Estructuras")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Text("\(viewModel.completedGamesCount)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Juegos")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Text("\(viewModel.streakDays)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Racha")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                    
                    NavigationLink(destination: StatisticsView(viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Estadísticas detalladas")
                        }
                    }
                    
                    NavigationLink(destination: AchievementsView(viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "medal.fill")
                            Text("Logros")
                            
                            Spacer()
                            
                            if viewModel.hasNewAchievements {
                                Text("\(viewModel.unviewedAchievementsCount)")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                
                Section(header: Text("Configuración")) {
                    Toggle("Notificaciones diarias", isOn: $viewModel.dailyNotificationsEnabled)
                    
                    Picker("Idioma preferido", selection: $viewModel.preferredLanguage) {
                        Text("Español").tag("es")
                        Text("Inglés").tag("en")
                        Text("Latín").tag("la")
                    }
                    
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.red)
                            Text("Reiniciar progreso")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Acerca de")) {
                    HStack {
                        Text("Versión")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://neuromemo.app/privacy")!) {
                        HStack {
                            Text("Política de privacidad")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Link(destination: URL(string: "https://neuromemo.app/support")!) {
                        HStack {
                            Text("Soporte")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Perfil")
            .alert(isPresented: $showingResetConfirmation) {
                Alert(
                    title: Text("Reiniciar progreso"),
                    message: Text("¿Estás seguro que deseas reiniciar todo tu progreso? Esta acción no se puede deshacer."),
                    primaryButton: .destructive(Text("Reiniciar")) {
                        viewModel.resetProgress()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

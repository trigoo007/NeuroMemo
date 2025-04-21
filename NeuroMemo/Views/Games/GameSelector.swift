// GameSelector.swift
import SwiftUI

struct GameSelector: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedGame: String?
    
    let games = [
        GameInfo(id: "countdown", name: "Contrarreloj", description: "Identifica tantas estructuras como puedas en 60 segundos", icon: "timer"),
        GameInfo(id: "touchandname", name: "Toca y Nombra", description: "Toca la estructura correcta al escuchar o leer su nombre", icon: "hand.tap"),
        GameInfo(id: "missinglabels", name: "Etiquetas Perdidas", description: "Coloca las etiquetas en las estructuras correctas", icon: "tag"),
        GameInfo(id: "connections", name: "Conexiones", description: "Conecta estructuras relacionadas entre sí", icon: "link")
    ]
    
    var body: some View {
        VStack {
            Text("Elige un juego")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(games, id: \.id) { game in
                        GameCard(game: game)
                            .onTapGesture {
                                selectedGame = game.id
                            }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Juegos")
        .sheet(item: $selectedGame) { gameId in
            gameView(for: gameId)
        }
    }
    
    func gameView(for gameId: String) -> some View {
        viewModel.startGame(type: gameId)
        
        switch gameId {
        case "countdown":
            return AnyView(
                CountdownGame(viewModel: viewModel)
                    .navigationBarTitle("Contrarreloj", displayMode: .inline)
            )
        case "touchandname":
            return AnyView(
                TouchAndNameGame(viewModel: viewModel)
                    .navigationBarTitle("Toca y Nombra", displayMode: .inline)
            )
        case "missinglabels":
            return AnyView(
                MissingLabelsGame(viewModel: viewModel)
                    .navigationBarTitle("Etiquetas Perdidas", displayMode: .inline)
            )
        case "connections":
            return AnyView(
                ConnectionsGame(viewModel: viewModel)
                    .navigationBarTitle("Conexiones", displayMode: .inline)
            )
        default:
            return AnyView(Text("Juego no encontrado"))
        }
    }
}

struct GameInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
}

struct GameCard: View {
    let game: GameInfo
    
    var body: some View {
        HStack {
            Image(systemName: game.icon)
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .padding(.leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(game.name)
                    .font(.headline)
                
                Text(game.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .padding(.trailing)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

extension String: Identifiable {
    public var id: String { self }
}

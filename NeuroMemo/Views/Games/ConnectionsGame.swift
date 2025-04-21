// ConnectionsGame.swift
import SwiftUI

struct ConnectionsGame: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var currentRound = 0
    @State private var maxRounds = 5
    @State private var score = 0
    @State private var structures: [AnatomicalStructure] = []
    @State private var connections: [Connection] = []
    @State private var userConnections: [(from: String, to: String)] = []
    @State private var selecting: String?
    @State private var showingFeedback = false
    @State private var gameActive = false
    @State private var showingResults = false
    
    var body: some View {
        VStack {
            if gameActive {
                // Información del juego
                HStack {
                    Text("Ronda: \(currentRound)/\(maxRounds)")
                    Spacer()
                    Text("Puntuación: \(score)")
                }
                .font(.headline)
                .padding()
                
                Text("Conecta las estructuras que están relacionadas entre sí")
                    .padding()
                
                // Cuadrícula de estructuras
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(structures) { structure in
                        StructureConnectionView(
                            structure: structure,
                            isSelected: selecting == structure.id,
                            hasConnections: userConnections.contains(where: { $0.from == structure.id || $0.to == structure.id })
                        )
                        .onTapGesture {
                            selectStructure(structure)
                        }
                    }
                }
                .padding()
                
                // Botón para verificar
                if userConnections.count >= connections.count {
                    Button("Verificar conexiones") {
                        checkConnections()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                
                // Feedback
                if showingFeedback {
                    VStack {
                        if score > currentRound - 1 {
                            Text("¡Bien hecho! Has conectado correctamente todas las estructuras.")
                                .foregroundColor(.green)
                        } else {
                            Text("Algunas conexiones no son correctas.")
                                .foregroundColor(.orange)
                        }
                        
                        Button("Continuar") {
                            nextRound()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .padding()
                }
            } else if showingResults {
                // Pantalla de resultados
                VStack(spacing: 20) {
                    Text("¡Fin del juego!")
                        .font(.title)
                    
                    Text("Puntuación final: \(score)/\(maxRounds)")
                        .font(.title2)
                    
                    Text("Has completado correctamente \(score) de \(maxRounds) rondas de conexiones.")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Jugar de nuevo") {
                        resetGame()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    
                    Button("Volver al menú") {
                        viewModel.exitGame()
                    }
                    .padding()
                }
                .padding()
            } else {
                // Pantalla de inicio
                VStack(spacing: 20) {
                    Text("Conexiones")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Conecta las estructuras anatómicas que están relacionadas entre sí.")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Stepper("Número de rondas: \(maxRounds)", value: $maxRounds, in: 3...10)
                        .padding()
                    
                    Button("Comenzar") {
                        startGame()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .padding()
            }
        }
        .navigationTitle("Conexiones")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func startGame() {
        currentRound = 0
        score = 0
        gameActive = true
        showingResults = false
        
        loadRound()
    }
    
    func loadRound() {
        // Obtener estructuras relacionadas
        let data = viewModel.getRelatedStructuresForGame()
        structures = data.structures
        connections = data.connections
        
        userConnections = []
        selecting = nil
        showingFeedback = false
        currentRound += 1
    }
    
    func selectStructure(_ structure: AnatomicalStructure) {
        if let selectedId = selecting {
            // Ya hay una estructura seleccionada
            if selectedId != structure.id {
                // Crear conexión
                let newConnection = (from: selectedId, to: structure.id)
                
                // Verificar que esta conexión no existe ya
                if !userConnections.contains(where: {
                    ($0.from == newConnection.from && $0.to == newConnection.to) ||
                    ($0.from == newConnection.to && $0.to == newConnection.from)
                }) {
                    userConnections.append(newConnection)
                }
            }
            selecting = nil
        } else {
            // Seleccionar esta estructura
            selecting = structure.id
        }
    }
    
    func checkConnections() {
        var correct = true
        
        for connection in connections {
            let found = userConnections.contains {
                ($0.from == connection.from && $0.to == connection.to) ||
                ($0.from == connection.to && $0.to == connection.from)
            }
            
            if !found {
                correct = false
                break
            }
        }
        
        if correct && userConnections.count == connections.count {
            score += 1
        }
        
        showingFeedback = true
    }
    
    func nextRound() {
        if currentRound >= maxRounds {
            endGame()
        } else {
            loadRound()
        }
    }
    
    func endGame() {
        gameActive = false
        showingResults = true
        
        // Registrar resultados del juego
        viewModel.saveGameResults(
            gameType: "connections",
            score: score,
            duration: 0
        )
    }
    
    func resetGame() {
        startGame()
    }
}

struct StructureConnectionView: View {
    let structure: AnatomicalStructure
    let isSelected: Bool
    let hasConnections: Bool
    
    var body: some View {
        VStack {
            if let imageURL = structure.imageURLs.first {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                }
                .frame(height: 100)
                .cornerRadius(12)
            }
            
            Text(structure.name)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            isSelected ? Color.blue.opacity(0.3) :
            (hasConnections ? Color.green.opacity(0.1) : Color(.systemBackground))
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Color.blue :
                    (hasConnections ? Color.green : Color.gray.opacity(0.3)),
                    lineWidth: 2
                )
        )
    }
}

struct Connection {
    let from: String
    let to: String
    let relationship: String
}

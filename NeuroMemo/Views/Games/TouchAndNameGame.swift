// TouchAndNameGame.swift
import SwiftUI

struct TouchAndNameGame: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var currentRound = 0
    @State private var maxRounds = 10
    @State private var score = 0
    @State private var options: [AnatomicalStructure] = []
    @State private var targetStructure: AnatomicalStructure?
    @State private var userSelection: String?
    @State private var showingFeedback = false
    @State private var isCorrect = false
    @State private var gameActive = false
    @State private var showingResults = false
    @State private var useVoicePrompt = false
    
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
                
                Spacer()
                
                // Instrucción
                if let target = targetStructure {
                    VStack {
                        Text("Toca la estructura:")
                            .font(.title2)
                        
                        Text(target.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()
                        
                        // Botón de voz
                        if useVoicePrompt {
                            Button(action: {
                                // Reproducir nombre en voz
                                viewModel.speakText(target.name)
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.largeTitle)
                                    .padding()
                            }
                        }
                    }
                    .padding()
                }
                
                // Cuadrícula de imágenes
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(options) { structure in
                        StructureOptionView(structure: structure, isSelected: userSelection == structure.id)
                            .onTapGesture {
                                selectOption(structure)
                            }
                            .disabled(showingFeedback)
                    }
                }
                .padding()
                
                // Feedback
                if showingFeedback {
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? .green : .red)
                            .font(.largeTitle)
                        
                        Text(isCorrect ? "¡Correcto!" : "Incorrecto")
                            .font(.title2)
                            .foregroundColor(isCorrect ? .green : .red)
                    }
                    .padding()
                    
                    Button("Continuar") {
                        nextRound()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                
                Spacer()
            } else if showingResults {
                // Pantalla de resultados
                VStack(spacing: 20) {
                    Text("¡Fin del juego!")
                        .font(.title)
                    
                    Text("Puntuación final: \(score)/\(maxRounds)")
                        .font(.title2)
                    
                    Text("Has identificado correctamente \(score) de \(maxRounds) estructuras.")
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
                    Text("Toca y Nombra")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Se te mostrará el nombre de una estructura anatómica. Toca la imagen correcta entre las opciones.")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Toggle("Usar indicaciones de voz", isOn: $useVoicePrompt)
                        .padding()
                    
                    Stepper("Número de rondas: \(maxRounds)", value: $maxRounds, in: 5...20, step: 5)
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
        .navigationTitle("Toca y Nombra")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func startGame() {
        currentRound = 0
        score = 0
        gameActive = true
        showingResults = false
        showingFeedback = false
        userSelection = nil
        
        loadRound()
    }
    
    func loadRound() {
        // Obtener opciones aleatorias
        options = viewModel.getRandomStructures(count: 4)
        
        // Seleccionar una al azar como objetivo
        if let selected = options.randomElement() {
            targetStructure = selected
        }
        
        currentRound += 1
        showingFeedback = false
        userSelection = nil
    }
    
    func selectOption(_ structure: AnatomicalStructure) {
        userSelection = structure.id
        isCorrect = structure.id == targetStructure?.id
        
        if isCorrect {
            score += 1
            viewModel.recordCorrectAnswer(structure: structure)
        } else {
            viewModel.recordIncorrectAnswer(structure: targetStructure!)
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
            gameType: "touchandname",
            score: score,
            duration: 0 // No hay tiempo en este juego
        )
    }
    
    func resetGame() {
        startGame()
    }
}

struct StructureOptionView: View {
    let structure: AnatomicalStructure
    let isSelected: Bool
    
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
                .frame(height: 120)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.3) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
        )
    }
}

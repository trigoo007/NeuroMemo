// CountdownGame.swift
import SwiftUI

struct CountdownGame: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var timeRemaining = 60
    @State private var correctAnswers = 0
    @State private var showingStructure: AnatomicalStructure?
    @State private var userAnswer = ""
    @State private var feedback: String?
    @State private var feedbackColor: Color = .primary
    @State private var isGameActive = false
    @State private var showingResults = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            if isGameActive {
                // Contador de tiempo
                Text("Tiempo: \(timeRemaining)")
                    .font(.headline)
                    .padding()
                    .onReceive(timer) { _ in
                        if timeRemaining > 0 && isGameActive {
                            timeRemaining -= 1
                        } else if timeRemaining == 0 {
                            endGame()
                        }
                    }
                
                // Puntuación actual
                Text("Aciertos: \(correctAnswers)")
                    .font(.title2)
                    .padding(.bottom)
                
                Spacer()
                
                // Imagen de la estructura
                if let structure = showingStructure, let imageURL = structure.imageURLs.first {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.2))
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding()
                }
                
                // Campo de respuesta
                TextField("Nombre de la estructura", text: $userAnswer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .disabled(timeRemaining == 0)
                    .onSubmit {
                        checkAnswer()
                    }
                
                // Botón para comprobar respuesta
                Button("Comprobar") {
                    checkAnswer()
                }
                .disabled(userAnswer.isEmpty || timeRemaining == 0)
                .padding()
                
                // Feedback para el usuario
                if let feedback = feedback {
                    Text(feedback)
                        .foregroundColor(feedbackColor)
                        .padding()
                }
                
                Spacer()
                
                // Botón para saltar
                Button("Saltar") {
                    loadNextStructure()
                }
                .padding()
            } else if showingResults {
                // Pantalla de resultados
                VStack(spacing: 20) {
                    Text("¡Fin del juego!")
                        .font(.title)
                    
                    Text("Puntuación final: \(correctAnswers)")
                        .font(.title2)
                    
                    Text("Has identificado \(correctAnswers) estructuras correctamente en 60 segundos.")
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
                    Text("Contrarreloj")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Identifica tantas estructuras como puedas en 60 segundos.")
                        .multilineTextAlignment(.center)
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
        .navigationTitle("Contrarreloj")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func startGame() {
        // Reiniciar variables
        timeRemaining = 60
        correctAnswers = 0
        feedback = nil
        
        // Cargar primera estructura
        loadNextStructure()
        
        // Activar juego
        isGameActive = true
        showingResults = false
    }
    
    func checkAnswer() {
        guard let currentStructure = showingStructure else { return }
        
        // Comprobar si la respuesta es correcta (ignorando mayúsculas/minúsculas)
        if userAnswer.lowercased() == currentStructure.name.lowercased() {
            correctAnswers += 1
            feedback = "¡Correcto!"
            feedbackColor = .green
            viewModel.recordCorrectAnswer(structure: currentStructure)
        } else {
            feedback = "Incorrecto. Era: \(currentStructure.name)"
            feedbackColor = .red
            viewModel.recordIncorrectAnswer(structure: currentStructure)
        }
        
        // Cargar siguiente estructura después de un breve retraso
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            loadNextStructure()
        }
    }
    
    func loadNextStructure() {
        userAnswer = ""
        feedback = nil
        showingStructure = viewModel.getRandomStructure()
    }
    
    func endGame() {
        isGameActive = false
        showingResults = true
        
        // Registrar resultados del juego
        viewModel.saveGameResults(
            gameType: "countdown",
            score: correctAnswers,
            duration: 60
        )
    }
    
    func resetGame() {
        startGame()
    }
}

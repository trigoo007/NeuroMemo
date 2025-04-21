// MissingLabelsGame.swift
import SwiftUI

struct MissingLabelsGame: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var currentRound = 0
    @State private var maxRounds = 5
    @State private var score = 0
    @State private var currentImage: AnatomicalImage?
    @State private var availableLabels: [String] = []
    @State private var placedLabels: [String: CGPoint] = [:]
    @State private var draggingLabel: String?
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
                
                // Imagen con puntos para colocar etiquetas
                if let image = currentImage {
                    GeometryReader { geometry in
                        ZStack {
                            // Imagen base
                            Image(uiImage: image.image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width)
                            
                            // Puntos para colocar etiquetas
                            ForEach(image.labels, id: \.id) { label in
                                let position = calculatePosition(for: label, in: geometry.size, image: image.image)
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 12, height: 12)
                                    
                                    // Mostrar etiqueta si está colocada
                                    if let placedPosition = placedLabels[label.text] {
                                        Text(label.text)
                                            .font(.caption)
                                            .padding(6)
                                            .background(Color.white)
                                            .cornerRadius(4)
                                            .shadow(radius: 2)
                                            .position(placedPosition)
                                            .gesture(
                                                DragGesture()
                                                    .onChanged { value in
                                                        draggingLabel = label.text
                                                        placedLabels[label.text] = value.location
                                                    }
                                                    .onEnded { _ in
                                                        draggingLabel = nil
                                                    }
                                            )
                                    }
                                }
                                .position(position)
                            }
                        }
                    }
                    .frame(height: 300)
                    .clipped()
                    .padding()
                    
                    // Etiquetas disponibles
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(availableLabels, id: \.self) { label in
                                if placedLabels[label] == nil {
                                    Text(label)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                        .onDrag {
                                            draggingLabel = label
                                            return NSItemProvider(object: label as NSString)
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    if availableLabels.allSatisfy({ placedLabels[$0] != nil }) {
                        Button("Verificar") {
                            checkAnswers()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
                
                // Feedback
                if showingFeedback {
                    VStack {
                        if score > currentRound - 1 {
                            Text("¡Bien hecho! Has colocado todas las etiquetas correctamente.")
                                .foregroundColor(.green)
                        } else {
                            Text("Algunas etiquetas no estaban en la posición correcta.")
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
                    
                    Text("Has etiquetado correctamente \(score) de \(maxRounds) imágenes.")
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
                    Text("Etiquetas Perdidas")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Coloca las etiquetas en las posiciones correctas de la imagen anatómica.")
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
        .navigationTitle("Etiquetas Perdidas")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func startGame() {
        currentRound = 0
        score = 0
        gameActive = true
        showingResults = false
        showingFeedback = false
        
        loadRound()
    }
    
    func loadRound() {
        // Obtener una imagen aleatoria con etiquetas
        currentImage = viewModel.getRandomLabeledImage()
        
        // Reiniciar etiquetas
        placedLabels = [:]
        
        // Cargar etiquetas disponibles
        if let image = currentImage {
            availableLabels = image.labels.map { $0.text }
        }
        
        currentRound += 1
        showingFeedback = false
    }
    
    func checkAnswers() {
        var correct = true
        
        if let image = currentImage {
            for label in image.labels {
                // Comprobar si la etiqueta está colocada cerca de su posición correcta
                if let placedPosition = placedLabels[label.text], let geometry = UIScreen.main.bounds.size {
                    let correctPosition = calculatePosition(for: label, in: geometry, image: image.image)
                    let distance = hypot(placedPosition.x - correctPosition.x, placedPosition.y - correctPosition.y)
                    
                    if distance > 30 { // Tolerancia de 30 puntos
                        correct = false
                        break
                    }
                } else {
                    correct = false
                    break
                }
            }
        }
        
        if correct {
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
            gameType: "missinglabels",
            score: score,
            duration: 0
        )
    }
    
    func resetGame() {
        startGame()
    }
    
    private func calculatePosition(for label: AnatomicalImage.Label, in size: CGSize, image: UIImage) -> CGPoint {
        let imageWidth = size.width
        let imageHeight = imageWidth * (image.size.height / image.size.width)
        
        return CGPoint(
            x: imageWidth * label.position.x,
            y: imageHeight * label.position.y
        )
    }
}

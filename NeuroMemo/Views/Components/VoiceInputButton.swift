// VoiceInputButton.swift
import SwiftUI

struct VoiceInputButton: View {
    let onActivation: () -> Void
    let onDeactivation: () -> Void
    let onTextReceived: (String) -> Void
    
    @State private var isListening = false
    @State private var animationAmount: CGFloat = 1
    
    var body: some View {
        ZStack {
            // Círculo exterior animado (visible cuando está escuchando)
            Circle()
                .stroke(lineWidth: 2)
                .foregroundColor(.blue)
                .scaleEffect(isListening ? animationAmount : 1)
                .opacity(isListening ? Double(2 - animationAmount) : 0)
            
            // Botón principal
            Button(action: {
                if isListening {
                    deactivate()
                } else {
                    activate()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isListening ? Color.red : Color.blue)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: isListening ? "stop.fill" : "mic.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }
            }
        }
        .frame(width: 70, height: 70)
        .onChange(of: isListening) { newValue in
            if newValue {
                // Iniciar animación al activar
                withAnimation(Animation.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                    animationAmount = 2
                }
            } else {
                // Detener animación al desactivar
                animationAmount = 1
            }
        }
    }
    
    private func activate() {
        isListening = true
        onActivation()
        
        // Simular recepción de texto después de un tiempo
        // En una implementación real, esto vendría del servicio de reconocimiento de voz
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if isListening {
                onTextReceived("Texto de ejemplo reconocido")
                deactivate()
            }
        }
    }
    
    private func deactivate() {
        isListening = false
        onDeactivation()
    }
}

struct VoiceInputButtonWithFeedback: View {
    @Binding var recognizedText: String
    @State private var isListening = false
    @State private var feedbackText = ""
    
    let whisperService = WhisperService()
    
    var body: some View {
        VStack {
            // Texto reconocido
            if !recognizedText.isEmpty {
                Text(recognizedText)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.bottom)
            }
            
            // Texto de feedback durante la escucha
            if isListening {
                Text(feedbackText)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)
            }
            
            // Botón de voz
            VoiceInputButton(
                onActivation: {
                    startListening()
                },
                onDeactivation: {
                    stopListening()
                },
                onTextReceived: { text in
                    recognizedText = text
                }
            )
        }
    }
    
    private func startListening() {
        isListening = true
        feedbackText = "Escuchando..."
        
        // Iniciar el servicio real de reconocimiento de voz
        whisperService.startRecording { result in
            switch result {
            case .success(let text):
                recognizedText = text
            case .failure(let error):
                feedbackText = "Error: \(error.localizedDescription)"
            }
            isListening = false
        }
    }
    
    private func stopListening() {
        isListening = false
        whisperService.stopRecording()
    }
}

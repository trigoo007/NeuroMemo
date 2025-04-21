// ProgressIndicators.swift
import SwiftUI

struct CircularProgressIndicator: View {
    let progress: Double
    var size: CGFloat = 60
    var lineWidth: CGFloat = 6
    var showPercentage: Bool = true
    var backgroundColor: Color = Color(.systemGray5)
    var foregroundColor: Color = .blue
    
    var body: some View {
        ZStack {
            // Círculo de fondo
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundColor(backgroundColor)
            
            // Círculo de progreso
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .foregroundColor(foregroundColor)
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: progress)
            
            // Texto de porcentaje
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.3))
                    .fontWeight(.bold)
            }
        }
        .frame(width: size, height: size)
    }
}

struct LinearProgressIndicator: View {
    let progress: Double
    var height: CGFloat = 8
    var backgroundColor: Color = Color(.systemGray5)
    var foregroundColor: Color = .blue
    var showPercentage: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .leading) {
                // Barra de fondo
                Rectangle()
                    .foregroundColor(backgroundColor)
                    .frame(height: height)
                    .cornerRadius(height / 2)
                
                // Barra de progreso
                Rectangle()
                    .foregroundColor(foregroundColor)
                    .frame(width: max(CGFloat(progress) * UIScreen.main.bounds.width * 0.8, 0), height: height)
                    .cornerRadius(height / 2)
                    .animation(.linear, value: progress)
            }
            
            // Texto de porcentaje
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

struct StudyProgressView: View {
    let userProgress: UserProgress
    let totalStructures: Int
    
    var studiedPercentage: Double {
        Double(userProgress.studiedStructures.count) / Double(max(totalStructures, 1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Progreso de estudio")
                        .font(.headline)
                    
                    Text("\(userProgress.studiedStructures.count) de \(totalStructures) estructuras")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressIndicator(progress: studiedPercentage)
            }
            
            LinearProgressIndicator(progress: studiedPercentage)
            
            // Estadísticas adicionales
            if userProgress.lastStudyDate != nil {
                HStack {
                    ProgressStat(
                        value: userProgress.studyStats.totalStudyTime.formattedTime,
                        label: "Tiempo total",
                        systemImage: "clock"
                    )
                    
                    Divider().frame(height: 40)
                    
                    ProgressStat(
                        value: "\(userProgress.streakDays)",
                        label: "Racha actual",
                        systemImage: "flame"
                    )
                    
                    Divider().frame(height: 40)
                    
                    ProgressStat(
                        value: userProgress.studyStats.accuracyPercentage,
                        label: "Precisión",
                        systemImage: "checkmark.circle"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ProgressStat: View {
    let value: String
    let label: String
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.headline)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

extension TimeInterval {
    var formattedTime: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

extension UserProgress.StudyStats {
    var accuracyPercentage: String {
        let total = correctAnswers + incorrectAnswers
        if total == 0 { return "N/A" }
        
        let percentage = (Double(correctAnswers) / Double(total)) * 100
        return "\(Int(percentage))%"
    }
}

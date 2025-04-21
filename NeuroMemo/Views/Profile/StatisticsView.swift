// StatisticsView.swift
import SwiftUI

struct StatisticsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var selectedTimeframe: Timeframe = .week
    
    enum Timeframe: String, CaseIterable {
        case week = "Semana"
        case month = "Mes"
        case allTime = "Total"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Selector de período
                Picker("Período", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tarjetas de resumen
                HStack(spacing: 15) {
                    StatCard(
                        title: "Tiempo de estudio",
                        value: viewModel.formattedStudyTime(timeframe: selectedTimeframe),
                        icon: "clock.fill"
                    )
                    
                    StatCard(
                        title: "Precisión",
                        value: viewModel.formattedAccuracy(timeframe: selectedTimeframe),
                        icon: "checkmark.circle.fill"
                    )
                }
                .padding(.horizontal)
                
                // Gráfico de actividad
                VStack(alignment: .leading) {
                    Text("Actividad diaria")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Aquí iría un gráfico de actividad
                    // Como SwiftUI no tiene gráficos nativos, usamos una representación simple
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(0..<7, id: \.self) { day in
                            let height = CGFloat(viewModel.getDailyActivity(day: day, timeframe: selectedTimeframe)) * 100
                            
                            VStack {
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 30, height: max(height, 20))
                                
                                Text(viewModel.getDayLabel(index: day))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 120)
                    .padding()
                }
                
                // Estructuras más estudiadas
                VStack(alignment: .leading) {
                    Text("Estructuras más estudiadas")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.getMostStudiedStructures(timeframe: selectedTimeframe)) { item in
                        HStack {
                            Text(item.structureName)
                            
                            Spacer()
                            
                            Text("\(item.count) sesiones")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
                
                // Estadísticas de juegos
                VStack(alignment: .leading) {
                    Text("Estadísticas de juegos")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.getGameStats(timeframe: selectedTimeframe)) { stat in
                        HStack {
                            Text(stat.gameName)
                            
                            Spacer()
                            
                            Text("Mejor: \(stat.highScore)")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Estadísticas")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

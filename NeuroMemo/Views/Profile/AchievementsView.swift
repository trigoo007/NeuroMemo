// AchievementsView.swift
import SwiftUI

struct AchievementsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(viewModel.getAllAchievements()) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        isUnlocked: viewModel.isAchievementUnlocked(id: achievement.id)
                    )
                    .onAppear {
                        if viewModel.isAchievementUnlocked(id: achievement.id) && !achievement.viewed {
                            viewModel.markAchievementAsViewed(id: achievement.id)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Logros")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isUnlocked ? achievement.icon : "lock.fill")
                .font(.system(size: 36))
                .foregroundColor(isUnlocked ? .yellow : .gray)
                .padding(.top, 12)
            
            Text(achievement.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            
            if isUnlocked, let date = achievement.dateEarned {
                Text(dateFormatter.string(from: date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(height: 180)
        .background(isUnlocked ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

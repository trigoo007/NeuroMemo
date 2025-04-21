// ProfileViewModel.swift
import Foundation
import Combine
import SwiftUI

class ProfileViewModel: ObservableObject {
    // Datos del perfil
    @Published var username: String {
        didSet {
            updateUserProfile()
        }
    }
    
    @Published var dailyNotificationsEnabled: Bool {
        didSet {
            updateNotificationSettings()
        }
    }
    
    @Published var preferredLanguage: String {
        didSet {
            updateLanguageSettings()
        }
    }
    
    // Datos calculados
    var studiedStructuresCount: Int {
        userDataManager.currentUser.studiedStructures.count
    }
    
    var completedGamesCount: Int {
        userDataManager.currentUser.completedGames.count
    }
    
    var streakDays: Int {
        userDataManager.currentUser.streakDays
    }
    
    var hasNewAchievements: Bool {
        !getUnviewedAchievements().isEmpty
    }
    
    var unviewedAchievementsCount: Int {
        getUnviewedAchievements().count
    }
    
    var formattedStartDate: String {
        guard let firstGame = userDataManager.currentUser.completedGames.sorted(by: { $0.date < $1.date }).first,
              let firstStudyDate = userDataManager.currentUser.lastStudyDate else {
            return "Hoy"
        }
        
        let earliestDate = min(firstGame.date, firstStudyDate)
        return dateFormatter.string(from: earliestDate)
    }
    
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
    
    // Dependencias
    private let userDataManager: UserDataManager
    private var cancellables = Set<AnyCancellable>()
    
    // Formateadores
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    init(userDataManager: UserDataManager = UserDataManager.shared) {
        self.userDataManager = userDataManager
        
        // Inicializar valores
        self.username = userDataManager.currentUser.username
        self.dailyNotificationsEnabled = UserDefaults.standard.bool(forKey: "dailyNotifications")
        self.preferredLanguage = UserDefaults.standard.string(forKey: "preferredLanguage") ?? "es"
        
        // Suscribirse a cambios en los datos del usuario
        userDataManager.$currentUser
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func resetProgress() {
        userDataManager.resetUserProgress()
    }
    
    // Métodos para estadísticas
    func formattedStudyTime(timeframe: StatisticsView.Timeframe) -> String {
        var totalTime: TimeInterval = 0
        
        switch timeframe {
        case .week:
            // Últimos 7 días
            totalTime = calculateStudyTimeForPeriod(days: 7)
        case .month:
            // Últimos 30 días
            totalTime = calculateStudyTimeForPeriod(days: 30)
        case .allTime:
            // Todo el tiempo
            totalTime = userDataManager.currentUser.studyStats.totalStudyTime
        }
        
        return totalTime.formattedTime
    }
    
    func formattedAccuracy(timeframe: StatisticsView.Timeframe) -> String {
        let userStats = userDataManager.currentUser.studyStats
        
        switch timeframe {
        case .week, .month:
            // Para períodos específicos, calcular basado en juegos recientes
            let correctAnswers = getCorrectAnswersForPeriod(
                days: timeframe == .week ? 7 : 30
            )
            let incorrectAnswers = getIncorrectAnswersForPeriod(
                days: timeframe == .week ? 7 : 30
            )
            
            let total = correctAnswers + incorrectAnswers
            if total == 0 { return "N/A" }
            
            let percentage = (Double(correctAnswers) / Double(total)) * 100
            return "\(Int(percentage))%"
            
        case .allTime:
            return userStats.accuracyPercentage
        }
    }
    
    func getDailyActivity(day: Int, timeframe: StatisticsView.Timeframe) -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        // Determinar el rango de días a considerar
        let daysToLookBack: Int
        switch timeframe {
        case .week:
            daysToLookBack = 7
        case .month:
            daysToLookBack = 30
        case .allTime:
            daysToLookBack = 30 // Para "Todo", mostrar los últimos 30 días en el gráfico
        }
        
        // Obtener fecha para el día específico
        guard let date = calendar.date(byAdding: .day, value: -daysToLookBack + day, to: today) else {
            return 0
        }
        
        // Contar actividades para ese día
        let activities = countActivitiesForDate(date)
        
        // Normalizar para el gráfico (valor máximo 1.0)
        let maxActivities = 10.0 // Definir un máximo para normalizar
        return min(Double(activities) / maxActivities, 1.0)
    }
    
    func getDayLabel(index: Int) -> String {
        let calendar = Calendar.current
        let today = Date()
        
        guard let date = calendar.date(byAdding: .day, value: -6 + index, to: today) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    func getMostStudiedStructures(timeframe: StatisticsView.Timeframe) -> [StructureStudyCount] {
        // Implementación simplificada - en un app real esto vendría de análisis de los datos
        let structures = userDataManager.currentUser.studiedStructures.prefix(5)
        
        return structures.enumerated().map { index, structure in
            let randomCount = Int.random(in: 3...15)
            return StructureStudyCount(
                id: structure.id,
                structureName: structure.name,
                count: randomCount
            )
        }
    }
    
    func getGameStats(timeframe: StatisticsView.Timeframe) -> [GameStat] {
        let games = ["countdown", "touchandname", "missinglabels", "connections"]
        let gameNames = ["Contrarreloj", "Toca y Nombra", "Etiquetas Perdidas", "Conexiones"]
        
        var stats: [GameStat] = []
        
        for (index, gameType) in games.enumerated() {
            let highScore = getHighScoreForGame(gameType: gameType, timeframe: timeframe)
            stats.append(GameStat(
                id: gameType,
                gameName: gameNames[index],
                highScore: highScore
            ))
        }
        
        return stats
    }
    
    // Métodos para logros
    func getAllAchievements() -> [Achievement] {
        let definitions: [Achievement] = [
            Achievement(
                id: "first_steps",
                title: "Primeros pasos",
                description: "Estudiar 5 estructuras anatómicas",
                icon: "figure.walk",
                dateEarned: getAchievementDate(id: "first_steps"),
                viewed: isAchievementViewed(id: "first_steps")
            ),
            Achievement(
                id: "dedicated_student",
                title: "Estudiante dedicado",
                description: "Estudiar 3 días seguidos",
                icon: "calendar.badge.clock",
                dateEarned: getAchievementDate(id: "dedicated_student"),
                viewed: isAchievementViewed(id: "dedicated_student")
            ),
            Achievement(
                id: "knowledge_master",
                title: "Maestro del conocimiento",
                description: "Obtener 90% de precisión en 10 juegos",
                icon: "brain",
                dateEarned: getAchievementDate(id: "knowledge_master"),
                viewed: isAchievementViewed(id: "knowledge_master")
            ),
            Achievement(
                id: "explorer",
                title: "Explorador",
                description: "Estudiar estructuras de 5 categorías diferentes",
                icon: "map",
                dateEarned: getAchievementDate(id: "explorer"),
                viewed: isAchievementViewed(id: "explorer")
            ),
            Achievement(
                id: "quick_thinker",
                title: "Pensador rápido",
                description: "Identificar 15 estructuras en el juego Contrarreloj",
                icon: "bolt",
                dateEarned: getAchievementDate(id: "quick_thinker"),
                viewed: isAchievementViewed(id: "quick_thinker")
            ),
            Achievement(
                id: "perfect_score",
                title: "Puntuación perfecta",
                description: "Obtener 100% en cualquier juego",
                icon: "star.fill",
                dateEarned: getAchievementDate(id: "perfect_score"),
                viewed: isAchievementViewed(id: "perfect_score")
            )
        ]
        
        return definitions
    }
    
    func isAchievementUnlocked(id: String) -> Bool {
        return userDataManager.currentUser.achievements.contains(where: { $0.id == id })
    }
    
    func isAchievementViewed(id: String) -> Bool {
        return userDataManager.currentUser.achievements.first(where: { $0.id == id })?.viewed ?? false
    }
    
    func getAchievementDate(id: String) -> Date? {
        return userDataManager.currentUser.achievements.first(where: { $0.id == id })?.dateEarned
    }
    
    func getUnviewedAchievements() -> [Achievement] {
        let unviewed = userDataManager.currentUser.achievements.filter { !$0.viewed }
        return unviewed
    }
    
    func markAchievementAsViewed(id: String) {
        var updatedUser = userDataManager.currentUser
        
        if let index = updatedUser.achievements.firstIndex(where: { $0.id == id }) {
            updatedUser.achievements[index].viewed = true
            userDataManager.saveUserProgress(updatedUser)
        }
    }
    
    // Métodos privados auxiliares
    private func updateUserProfile() {
        var updatedUser = userDataManager.currentUser
        updatedUser.username = username
        userDataManager.saveUserProgress(updatedUser)
    }
    
    private func updateNotificationSettings() {
        UserDefaults.standard.set(dailyNotificationsEnabled, forKey: "dailyNotifications")
        
        // Configurar notificaciones si están habilitadas
        if dailyNotificationsEnabled {
            requestNotificationPermission()
        }
    }
    
    private func updateLanguageSettings() {
        UserDefaults.standard.set(preferredLanguage, forKey: "preferredLanguage")
        
        // Cambiar el idioma de la aplicación
        // Esto requeriría una implementación más compleja en una app real
    }
    
    private func requestNotificationPermission() {
        // Código para solicitar permisos de notificaciones
        // En una implementación real, esto utilizaría UNUserNotificationCenter
    }
    
    private func calculateStudyTimeForPeriod(days: Int) -> TimeInterval {
        // Esta es una implementación simulada
        // En una app real, esto vendría de análisis de los datos de estudio
        let totalTime = userDataManager.currentUser.studyStats.totalStudyTime
        return totalTime * Double(days) / 30.0 // Simplificación
    }
    
    private func getCorrectAnswersForPeriod(days: Int) -> Int {
        // Implementación simulada
        return Int(Double(userDataManager.currentUser.studyStats.correctAnswers) * Double(days) / 30.0)
    }
    
    private func getIncorrectAnswersForPeriod(days: Int) -> Int {
        // Implementación simulada
        return Int(Double(userDataManager.currentUser.studyStats.incorrectAnswers) * Double(days) / 30.0)
    }
    
    private func countActivitiesForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        
        // Contar juegos completados en esa fecha
        let gamesCount = userDataManager.currentUser.completedGames.filter { game in
            calendar.isDate(game.date, inSameDayAs: date)
        }.count
        
        // Simulamos sesiones de estudio
        // En una app real, tendríamos un registro de sesiones de estudio
        let studySession = (gamesCount > 0) ? Int.random(in: 1...3) : Int.random(in: 0...2)
        
        return gamesCount + studySession
    }
    
    private func getHighScoreForGame(gameType: String, timeframe: StatisticsView.Timeframe) -> String {
        // Filtrar juegos por tipo
        let games = userDataManager.currentUser.completedGames.filter { $0.gameType == gameType }
        
        // Filtrar por período
        let filteredGames: [CompletedGame]
        let calendar = Calendar.current
        let today = Date()
        
        switch timeframe {
        case .week:
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            filteredGames = games.filter { $0.date >= sevenDaysAgo }
        case .month:
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
            filteredGames = games.filter { $0.date >= thirtyDaysAgo }
        case .allTime:
            filteredGames = games
        }
        
        // Encontrar puntuación máxima
        guard let highestScore = filteredGames.max(by: { $0.score < $1.score })?.score else {
            return "-"
        }
        
        return "\(highestScore)"
    }
}

struct StructureStudyCount: Identifiable {
    let id: String
    let structureName: String
    let count: Int
}

struct GameStat: Identifiable {
    let id: String
    let gameName: String
    let highScore: String
}

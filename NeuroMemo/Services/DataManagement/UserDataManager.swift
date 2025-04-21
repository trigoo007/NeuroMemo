// UserDataManager.swift
import Foundation
import Combine

class UserDataManager {
    static let shared = UserDataManager()
    
    private let coreDataManager = CoreDataManager.shared
    private let userDefaultsKey = "com.neuromemo.userdata"
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentUser: UserProgress
    
    private init() {
        // Intentar cargar desde Core Data primero
        if let savedUser = coreDataManager.fetchUserProgress() {
            self.currentUser = savedUser
        } else {
            // Intentar cargar desde UserDefaults como respaldo
            if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
               let decodedUser = try? JSONDecoder().decode(UserProgress.self, from: data) {
                self.currentUser = decodedUser
            } else {
                // Crear nuevo usuario
                self.currentUser = UserProgress(
                    id: UUID().uuidString,
                    username: "Usuario",
                    studiedStructures: [],
                    completedGames: [],
                    studyStats: UserProgress.StudyStats(
                        totalStudyTime: 0,
                        correctAnswers: 0,
                        incorrectAnswers: 0
                    ),
                    lastStudyDate: nil,
                    streakDays: 0,
                    achievements: []
                )
            }
        }
        
        // Configurar guardado automático
        setupAutoSave()
    }
    
    private func setupAutoSave() {
        $currentUser
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] user in
                self?.saveUserProgress(user)
            }
            .store(in: &cancellables)
    }
    
    func saveUserProgress(_ user: UserProgress) {
        // Guardar en Core Data
        coreDataManager.saveUserProgress(user)
        
        // Guardar en UserDefaults como respaldo
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func recordStudySession(structures: [AnatomicalStructure], duration: TimeInterval) {
        var updatedUser = currentUser
        
        // Actualizar estructuras estudiadas
        for structure in structures {
            if !updatedUser.studiedStructures.contains(where: { $0.id == structure.id }) {
                updatedUser.studiedStructures.append(structure)
            }
        }
        
        // Actualizar tiempo de estudio
        updatedUser.studyStats.totalStudyTime += duration
        
        // Actualizar fecha de último estudio
        let today = Date()
        
        // Calcular racha de días
        if let lastDate = updatedUser.lastStudyDate {
            let calendar = Calendar.current
            if calendar.isDate(lastDate, inSameDayAs: today) {
                // Ya estudiado hoy, no cambiar la racha
            } else if let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: today),
                      calendar.isDate(lastDate, inSameDayAs: yesterdayDate) {
                // Estudiado ayer, incrementar racha
                updatedUser.streakDays += 1
            } else {
                // No estudiado ayer, reiniciar racha
                updatedUser.streakDays = 1
            }
        } else {
            // Primera vez estudiando, iniciar racha
            updatedUser.streakDays = 1
        }
        
        updatedUser.lastStudyDate = today
        
        // Actualizar usuario
        currentUser = updatedUser
    }
    
    func recordGameCompletion(game: CompletedGame) {
        var updatedUser = currentUser
        updatedUser.completedGames.append(game)
        currentUser = updatedUser
        
        // Verificar y otorgar logros
        checkAchievements()
    }
    
    func recordQuizAnswer(correct: Bool) {
        var updatedUser = currentUser
        
        if correct {
            updatedUser.studyStats.correctAnswers += 1
        } else {
            updatedUser.studyStats.incorrectAnswers += 1
        }
        
        currentUser = updatedUser
    }
    
    private func checkAchievements() {
        var newAchievements: [Achievement] = []
        
        // Logro: Primeros pasos
        if currentUser.studiedStructures.count >= 5 &&
           !currentUser.achievements.contains(where: { $0.id == "first_steps" }) {
            newAchievements.append(Achievement(
                id: "first_steps",
                title: "Primeros pasos",
                description: "Estudiar 5 estructuras anatómicas",
                dateEarned: Date()
            ))
        }
        
        // Logro: Estudiante dedicado
        if currentUser.streakDays >= 3 &&
           !currentUser.achievements.contains(where: { $0.id == "dedicated_student" }) {
            newAchievements.append(Achievement(
                id: "dedicated_student",
                title: "Estudiante dedicado",
                description: "Estudiar 3 días seguidos",
                dateEarned: Date()
            ))
        }
        
        // Añadir nuevos logros
        if !newAchievements.isEmpty {
            var updatedUser = currentUser
            updatedUser.achievements.append(contentsOf: newAchievements)
            currentUser = updatedUser
        }
    }
    
    func resetUserProgress() {
        currentUser = UserProgress(
            id: UUID().uuidString,
            username: "Usuario",
            studiedStructures: [],
            completedGames: [],
            studyStats: UserProgress.StudyStats(
                totalStudyTime: 0,
                correctAnswers: 0,
                incorrectAnswers: 0
            ),
            lastStudyDate: nil,
            streakDays: 0,
            achievements: []
        )
    }
}

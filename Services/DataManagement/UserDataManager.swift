import Foundation
import CoreData
import UserNotifications

class UserDataManager {
    static let shared = UserDataManager()
    
    private(set) var currentUser: UserProgress
    
    private init() {
        self.currentUser = loadUserProgress() ?? UserProgress(userId: UUID().uuidString)
    }
    
    // MARK: - User Progress Operations
    
    func saveUserProgress() {
        let context = CoreDataManager.shared.viewContext
        
        // Buscar si el usuario ya existe
        let fetchRequest: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", currentUser.userId)
        
        do {
            let results = try context.fetch(fetchRequest)
            let userEntity: UserProgressEntity
            
            if let existingUser = results.first {
                userEntity = existingUser
            } else {
                userEntity = CoreDataManager.shared.create(UserProgressEntity.self)
                userEntity.userId = currentUser.userId
            }
            
            // Actualizar los datos básicos
            userEntity.totalStudyTime = currentUser.totalStudyTime
            userEntity.lastActiveDate = currentUser.lastActiveDate
            userEntity.selectedLanguage = currentUser.settings.language
            userEntity.notificationsEnabled = currentUser.settings.notificationsEnabled
            
            // Estructuras estudiadas
            let existingStudied = userEntity.studiedStructures as? Set<StudiedStructureEntity> ?? []
            for existing in existingStudied {
                userEntity.removeFromStudiedStructures(existing)
                context.delete(existing)
            }
            
            for studied in currentUser.studiedStructures {
                let studiedEntity = CoreDataManager.shared.create(StudiedStructureEntity.self)
                studiedEntity.structureId = studied.structureId
                studiedEntity.timeStudied = studied.timeStudied
                studiedEntity.lastReviewDate = studied.lastReviewDate
                studiedEntity.confidenceLevel = Int16(studied.confidenceLevel)
                userEntity.addToStudiedStructures(studiedEntity)
            }
            
            // Juegos completados
            let existingGames = userEntity.completedGames as? Set<CompletedGameEntity> ?? []
            for existing in existingGames {
                userEntity.removeFromCompletedGames(existing)
                context.delete(existing)
            }
            
            for game in currentUser.completedGames {
                let gameEntity = CoreDataManager.shared.create(CompletedGameEntity.self)
                gameEntity.gameId = game.gameId
                gameEntity.gameType = game.gameType
                gameEntity.completionDate = game.completionDate
                gameEntity.score = game.score
                gameEntity.timeSpent = game.timeSpent
                userEntity.addToCompletedGames(gameEntity)
            }
            
            // Logros
            let existingAchievements = userEntity.achievements as? Set<AchievementEntity> ?? []
            for existing in existingAchievements {
                userEntity.removeFromAchievements(existing)
                context.delete(existing)
            }
            
            for achievement in currentUser.achievements {
                let achievementEntity = CoreDataManager.shared.create(AchievementEntity.self)
                achievementEntity.achievementId = achievement.id
                achievementEntity.name = achievement.name
                achievementEntity.description = achievement.description
                achievementEntity.dateUnlocked = achievement.dateUnlocked
                userEntity.addToAchievements(achievementEntity)
            }
            
            CoreDataManager.shared.saveContext()
            print("Progreso del usuario guardado correctamente")
        } catch {
            print("Error al guardar el progreso del usuario: \(error)")
        }
    }
    
    func loadUserProgress() -> UserProgress? {
        let fetchRequest: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
        
        do {
            let results = try CoreDataManager.shared.viewContext.fetch(fetchRequest)
            
            if let userEntity = results.first {
                // Convertir desde Entity a nuestro modelo
                let userId = userEntity.userId ?? ""
                var userProgress = UserProgress(userId: userId)
                
                userProgress.totalStudyTime = userEntity.totalStudyTime
                userProgress.lastActiveDate = userEntity.lastActiveDate
                
                // Configurar ajustes
                userProgress.settings.language = userEntity.selectedLanguage ?? "es"
                userProgress.settings.notificationsEnabled = userEntity.notificationsEnabled
                
                // Cargar estructuras estudiadas
                if let studiedEntities = userEntity.studiedStructures as? Set<StudiedStructureEntity> {
                    userProgress.studiedStructures = studiedEntities.map { entity in
                        return StudiedStructure(
                            structureId: entity.structureId ?? "",
                            timeStudied: entity.timeStudied,
                            lastReviewDate: entity.lastReviewDate ?? Date(),
                            confidenceLevel: Int(entity.confidenceLevel)
                        )
                    }
                }
                
                // Cargar juegos completados
                if let gameEntities = userEntity.completedGames as? Set<CompletedGameEntity> {
                    userProgress.completedGames = gameEntities.map { entity in
                        return CompletedGame(
                            gameId: entity.gameId ?? "",
                            gameType: entity.gameType ?? "",
                            completionDate: entity.completionDate ?? Date(),
                            score: entity.score,
                            timeSpent: entity.timeSpent
                        )
                    }
                }
                
                // Cargar logros
                if let achievementEntities = userEntity.achievements as? Set<AchievementEntity> {
                    userProgress.achievements = achievementEntities.map { entity in
                        return Achievement(
                            id: entity.achievementId ?? "",
                            name: entity.name ?? "",
                            description: entity.description ?? "",
                            dateUnlocked: entity.dateUnlocked
                        )
                    }
                }
                
                return userProgress
            }
        } catch {
            print("Error al cargar el progreso del usuario: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Estadísticas y seguimiento
    
    func recordStudySession(structureId: String, duration: TimeInterval) {
        // Encontrar o crear una estructura estudiada
        if let index = currentUser.studiedStructures.firstIndex(where: { $0.structureId == structureId }) {
            currentUser.studiedStructures[index].timeStudied += duration
            currentUser.studiedStructures[index].lastReviewDate = Date()
        } else {
            let newStructure = StudiedStructure(
                structureId: structureId,
                timeStudied: duration,
                lastReviewDate: Date(),
                confidenceLevel: 1
            )
            currentUser.studiedStructures.append(newStructure)
        }
        
        // Actualizar tiempo total
        currentUser.totalStudyTime += duration
        currentUser.lastActiveDate = Date()
        
        // Guardar cambios
        saveUserProgress()
    }
    
    // MARK: - Configuración
    
    func updateNotificationSettings(enabled: Bool) {
        currentUser.settings.notificationsEnabled = enabled
        saveUserProgress()
        
        // Aquí implementar la solicitud de permisos con UserNotifications
        if enabled {
            let userNotificationCenter = UNUserNotificationCenter.current()
            userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    print("Permisos de notificación concedidos")
                    self.scheduleReminders()
                } else if let error = error {
                    print("Error al solicitar permisos: \(error.localizedDescription)")
                }
            }
        } else {
            // Cancelar todas las notificaciones programadas
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    private func scheduleReminders() {
        // Programar recordatorios de estudio diarios
        let content = UNMutableNotificationContent()
        content.title = "Hora de estudiar"
        content.body = "¡No olvides repasar las estructuras neuroanatómicas de hoy!"
        content.sound = .default
        
        // Crear un disparador que se active todos los días a las 18:00
        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyStudyReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func updateLanguageSettings(language: String) {
        currentUser.settings.language = language
        saveUserProgress()
        
        // Cambiar el idioma de la aplicación
        // Esto requiere un mecanismo para reiniciar la UI o usar librerías de localización avanzadas
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Normalmente, esto requeriría reiniciar la aplicación para que los cambios tengan efecto
        // En una implementación real, podríamos mostrar un diálogo solicitando al usuario reiniciar
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
    }
}
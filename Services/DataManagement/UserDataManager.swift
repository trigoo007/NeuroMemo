import Foundation
import CoreData

class UserDataManager {
    static let shared = UserDataManager()
    
    private let persistentContainer: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "NeuroMemo")
        
        // Configurar opciones de migración
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error al cargar Core Data: \(error.localizedDescription)")
            }
        }
        
        context = persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Operaciones CRUD
    
    func saveUserProgress(_ userToSave: UserProgress) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Obtener o crear la entidad UserProgress
            let fetchRequest: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userToSave.userId)
            
            let userEntity: UserProgressEntity
            if let existingEntity = try? self.context.fetch(fetchRequest).first {
                userEntity = existingEntity
            } else {
                userEntity = UserProgressEntity(context: self.context)
            }
            
            // Mapear propiedades básicas
            userEntity.userId = userToSave.userId
            userEntity.username = userToSave.username
            userEntity.totalStudyTime = userToSave.totalStudyTime
            userEntity.lastActiveDate = userToSave.lastActiveDate
            userEntity.lastStudyDate = userToSave.lastStudyDate
            userEntity.streakDays = Int16(userToSave.streakDays)
            
            // Mapear settings
            userEntity.selectedLanguage = userToSave.settings.language
            userEntity.notificationsEnabled = userToSave.settings.notificationsEnabled
            
            // Mapear studyStats
            userEntity.totalCorrectAnswers = Int32(userToSave.studyStats.correctAnswers)
            userEntity.totalIncorrectAnswers = Int32(userToSave.studyStats.incorrectAnswers)
            
            // Actualizar relaciones con lógica de upsert
            self.updateStudiedStructures(for: userEntity, with: userToSave.studiedStructures)
            self.updateCompletedGames(for: userEntity, with: userToSave.completedGames)
            self.updateAchievements(for: userEntity, with: userToSave.achievements)
            
            // Guardar cambios
            do {
                try self.context.save()
            } catch {
                print("Error al guardar UserProgress: \(error.localizedDescription)")
            }
        }
    }
    
    func loadUserProgress(userId: String) -> UserProgress? {
        let fetchRequest: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        
        guard let userEntity = try? context.fetch(fetchRequest).first else {
            return nil
        }
        
        // Crear UserProgress desde la entidad
        var userProgress = UserProgress(userId: userId)
        
        // Mapear propiedades básicas
        userProgress.username = userEntity.username ?? "Usuario"
        userProgress.totalStudyTime = userEntity.totalStudyTime
        userProgress.lastActiveDate = userEntity.lastActiveDate ?? Date()
        userProgress.lastStudyDate = userEntity.lastStudyDate
        userProgress.streakDays = Int(userEntity.streakDays)
        
        // Mapear settings
        userProgress.settings.language = userEntity.selectedLanguage ?? "es"
        userProgress.settings.notificationsEnabled = userEntity.notificationsEnabled
        
        // Mapear studyStats
        userProgress.studyStats.correctAnswers = Int(userEntity.totalCorrectAnswers)
        userProgress.studyStats.incorrectAnswers = Int(userEntity.totalIncorrectAnswers)
        
        // Cargar relaciones
        if let studiedStructures = userEntity.studiedStructures as? Set<StudiedStructureEntity> {
            userProgress.studiedStructures = studiedStructures.map { entity in
                StudiedStructure(
                    structureId: entity.structureId ?? "",
                    timeStudied: entity.timeStudied,
                    lastReviewDate: entity.lastReviewDate ?? Date(),
                    confidenceLevel: Int(entity.confidenceLevel)
                )
            }
        }
        
        if let completedGames = userEntity.completedGames as? Set<CompletedGameEntity> {
            userProgress.completedGames = completedGames.map { entity in
                CompletedGame(
                    gameId: entity.gameId ?? "",
                    gameType: entity.gameType ?? "",
                    completionDate: entity.completionDate ?? Date(),
                    score: entity.score,
                    timeSpent: entity.timeSpent
                )
            }
        }
        
        if let achievements = userEntity.achievements as? Set<AchievementEntity> {
            userProgress.achievements = achievements.map { entity in
                Achievement(
                    id: entity.achievementId ?? "",
                    name: entity.name ?? "",
                    description: entity.description ?? "",
                    dateUnlocked: entity.dateUnlocked,
                    viewed: entity.viewed
                )
            }
        }
        
        return userProgress
    }
    
    // MARK: - Métodos de ayuda para actualizar relaciones
    
    private func updateStudiedStructures(for userEntity: UserProgressEntity, with structures: [StudiedStructure]) {
        let existingStructures = userEntity.studiedStructures as? Set<StudiedStructureEntity> ?? []
        var updatedIDs = Set<String>()
        
        for structure in structures {
            updatedIDs.insert(structure.structureId)
            
            if let existing = existingStructures.first(where: { $0.structureId == structure.structureId }) {
                // Actualizar entidad existente
                existing.timeStudied = structure.timeStudied
                existing.lastReviewDate = structure.lastReviewDate
                existing.confidenceLevel = Int16(structure.confidenceLevel)
            } else {
                // Crear nueva entidad
                let newEntity = StudiedStructureEntity(context: context)
                newEntity.structureId = structure.structureId
                newEntity.timeStudied = structure.timeStudied
                newEntity.lastReviewDate = structure.lastReviewDate
                newEntity.confidenceLevel = Int16(structure.confidenceLevel)
                userEntity.addToStudiedStructures(newEntity)
            }
        }
        
        // Eliminar entidades obsoletas
        for existing in existingStructures where !updatedIDs.contains(existing.structureId ?? "") {
            userEntity.removeFromStudiedStructures(existing)
            context.delete(existing)
        }
    }
    
    private func updateCompletedGames(for userEntity: UserProgressEntity, with games: [CompletedGame]) {
        let existingGames = userEntity.completedGames as? Set<CompletedGameEntity> ?? []
        var updatedIDs = Set<String>()
        
        for game in games {
            updatedIDs.insert(game.gameId)
            
            if let existing = existingGames.first(where: { $0.gameId == game.gameId }) {
                // Actualizar entidad existente
                existing.gameType = game.gameType
                existing.completionDate = game.completionDate
                existing.score = game.score
                existing.timeSpent = game.timeSpent
            } else {
                // Crear nueva entidad
                let newEntity = CompletedGameEntity(context: context)
                newEntity.gameId = game.gameId
                newEntity.gameType = game.gameType
                newEntity.completionDate = game.completionDate
                newEntity.score = game.score
                newEntity.timeSpent = game.timeSpent
                userEntity.addToCompletedGames(newEntity)
            }
        }
        
        // Eliminar entidades obsoletas
        for existing in existingGames where !updatedIDs.contains(existing.gameId ?? "") {
            userEntity.removeFromCompletedGames(existing)
            context.delete(existing)
        }
    }
    
    private func updateAchievements(for userEntity: UserProgressEntity, with achievements: [Achievement]) {
        let existingAchievements = userEntity.achievements as? Set<AchievementEntity> ?? []
        var updatedIDs = Set<String>()
        
        for achievement in achievements {
            updatedIDs.insert(achievement.id)
            
            if let existing = existingAchievements.first(where: { $0.achievementId == achievement.id }) {
                // Actualizar entidad existente
                existing.name = achievement.name
                existing.achievementDescription = achievement.description
                existing.dateUnlocked = achievement.dateUnlocked
                existing.viewed = achievement.viewed
            } else {
                // Crear nueva entidad
                let newEntity = AchievementEntity(context: context)
                newEntity.achievementId = achievement.id
                newEntity.name = achievement.name
                newEntity.achievementDescription = achievement.description
                newEntity.dateUnlocked = achievement.dateUnlocked
                newEntity.viewed = achievement.viewed
                userEntity.addToAchievements(newEntity)
            }
        }
        
        // Eliminar entidades obsoletas
        for existing in existingAchievements where !updatedIDs.contains(existing.achievementId ?? "") {
            userEntity.removeFromAchievements(existing)
            context.delete(existing)
        }
    }
} 
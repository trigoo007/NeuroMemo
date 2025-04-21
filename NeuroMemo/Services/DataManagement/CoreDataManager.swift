import Foundation
import CoreData

class CoreDataManager {
    // Singleton compartido
    static let shared = CoreDataManager()
    
    // Contenedor de Core Data
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NeuroMemo")
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Error al cargar Core Data: \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    // Contexto principal
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Contexto de segundo plano para operaciones
    func backgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // Inicialización privada para singleton
    private init() {}
    
    // MARK: - Operaciones de Core Data
    
    /// Guardar cambios en contexto
    func saveContext(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error al guardar contexto: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// Ejecutar en contexto de segundo plano
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            block(context)
        }
    }
    
    // MARK: - Métodos de Consulta Generales
    
    /// Obtener objetos de tipo específico
    func fetchEntities<T: NSManagedObject>(
        entityName: String,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        limit: Int? = nil,
        context: NSManagedObjectContext? = nil
    ) -> [T] {
        let context = context ?? viewContext
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        if let limit = limit {
            fetchRequest.fetchLimit = limit
        }
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error al obtener entidades \(entityName): \(error)")
            return []
        }
    }
    
    /// Contar entidades que cumplen predicado
    func countEntities(
        entityName: String,
        predicate: NSPredicate? = nil,
        context: NSManagedObjectContext? = nil
    ) -> Int {
        let context = context ?? viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("Error al contar entidades \(entityName): \(error)")
            return 0
        }
    }
    
    /// Eliminar objetos que cumplen predicado
    func deleteEntities(
        entityName: String,
        predicate: NSPredicate? = nil,
        context: NSManagedObjectContext? = nil
    ) {
        let context = context ?? viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }
        } catch {
            print("Error al eliminar entidades \(entityName): \(error)")
        }
    }
}
